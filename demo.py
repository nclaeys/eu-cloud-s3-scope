#!/usr/bin/env python3
"""
Fine-grained S3 access control demo.

Reads Terraform outputs from a module directory and verifies that Alice (hr/)
and Bob (sales/) can only access their own prefix.

Usage:
    python demo.py --tf-dir scaleway/bucket-policy
"""

import argparse
import json
import subprocess
import sys

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"
BOLD = "\033[1m"


def ok(msg):
    print(f"  {GREEN}PASS{RESET}  {msg}")


def fail(msg):
    print(f"  {RED}FAIL{RESET}  {msg}")


def skip(msg):
    print(f"  {YELLOW}SKIP{RESET}  {msg}")


def s3_client(endpoint, access_key, secret_key, payload_signing=False):
    extra = (
        dict(
            request_checksum_calculation="when_required",
            response_checksum_validation="when_required",
        )
        if payload_signing
        else {}
    )
    return boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name="us-east-1",
        config=Config(s3={"payload_signing_enabled": payload_signing}, **extra),
    )


def expect_allow(label, fn):
    try:
        fn()
        ok(label)
        return True
    except ClientError as e:
        code = e.response["Error"]["Code"]
        fail(f"{label}  [{code}]")
        return False


def expect_deny(label, fn):
    try:
        fn()
        fail(f"{label}  [no error — access should have been denied]")
        return False
    except ClientError as e:
        code = e.response["Error"]["Code"]
        if code in ("AccessDenied", "403", "AllAccessDisabled"):
            ok(f"{label}  [{code}]")
            return True
        fail(f"{label}  [unexpected error: {code}]")
        return False


def run_puts(client, bucket, own_prefix, other_prefix, username):
    content = b"demo data"
    own_key = f"{own_prefix}demo.txt"
    other_key = f"{other_prefix}demo.txt"

    print(f"\n{BOLD}{username}{RESET} — PUT phase")

    passed = 0
    checks = [
        (expect_allow, f"PUT  {own_key}",   lambda: client.put_object(Bucket=bucket, Key=own_key, Body=content)),
        (expect_deny,  f"PUT  {other_key}", lambda: client.put_object(Bucket=bucket, Key=other_key, Body=content)),
    ]
    for fn, label, op in checks:
        if fn(label, op):
            passed += 1
    return passed, len(checks)


def run_gets(client, bucket, own_prefix, other_prefix, username):
    own_key = f"{own_prefix}demo.txt"
    other_key = f"{other_prefix}demo.txt"

    print(f"\n{BOLD}{username}{RESET} — GET phase")

    passed = 0
    checks = [
        (expect_allow, f"GET  {own_key}",          lambda: client.get_object(Bucket=bucket, Key=own_key)),
        (expect_allow, f"LIST prefix={own_prefix}", lambda: client.list_objects_v2(Bucket=bucket, Prefix=own_prefix)),
        (expect_deny,  f"GET  {other_key}",         lambda: client.get_object(Bucket=bucket, Key=other_key)),
    ]
    for fn, label, op in checks:
        if fn(label, op):
            passed += 1
    return passed, len(checks)


def load_from_terraform(tf_dir):
    result = subprocess.run(
        ["terraform", "output", "-json"],
        cwd=tf_dir,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"terraform output failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)
    outputs = json.loads(result.stdout)

    def get(key):
        entry = outputs.get(key)
        if entry is None:
            print(f"Missing terraform output: {key}", file=sys.stderr)
            sys.exit(1)
        return entry["value"]

    return {
        "endpoint": get("s3_endpoint"),
        "bucket": get("bucket_name"),
        "alice_key": get("alice_access_key_id"),
        "alice_secret": get("alice_secret_key"),
        "bob_key": get("bob_access_key_id"),
        "bob_secret": get("bob_secret_key"),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--tf-dir", metavar="DIR", help="Terraform module directory to read outputs from")
    parser.add_argument("--payload-signing", action="store_true", help="Enable payload signing (required for UpCloud)")

    args = parser.parse_args()
    cfg = load_from_terraform(args.tf_dir)

    print(f"\n{BOLD}Endpoint:{RESET} {cfg['endpoint']}")
    print(f"{BOLD}Bucket:  {RESET} {cfg['bucket']}")

    alice = s3_client(cfg["endpoint"], cfg["alice_key"], cfg["alice_secret"], args.payload_signing)
    bob = s3_client(cfg["endpoint"], cfg["bob_key"], cfg["bob_secret"], args.payload_signing)

    total_passed = 0
    total_checks = 0
    user_permissions = [
        (alice, "hr/", "sales/", "Alice (HR)"),
        (bob, "sales/", "hr/", "Bob (Sales)"),
    ]

    print(f"\n{BOLD}--- Phase 1: PUT ---{RESET}")
    for client, own, other, name in user_permissions:
        p, t = run_puts(client, cfg["bucket"], own, other, name)
        total_passed += p
        total_checks += t

    print(f"\n{BOLD}--- Phase 2: GET ---{RESET}")
    for client, own, other, name in user_permissions:
        p, t = run_gets(client, cfg["bucket"], own, other, name)
        total_passed += p
        total_checks += t

    print(f"\n{BOLD}Result: {total_passed}/{total_checks} checks passed{RESET}")
    sys.exit(0 if total_passed == total_checks else 1)


if __name__ == "__main__":
    main()

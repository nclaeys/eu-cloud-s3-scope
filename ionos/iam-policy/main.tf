# IONOS does NOT support user-level S3 IAM policies.
# S3 access control in IONOS is exclusively resource-based (bucket policies).
# This setup creates users and keys but leaves the bucket WITHOUT a bucket policy,
# demonstrating that Alice and Bob have zero access by default.
terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "ionoscloud" {
  #token = var.ionos_token We lookat IONOS_TOKEN in env vars
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "alice" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "bob" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "ionoscloud_user" "alice" {
  first_name     = "Alice"
  last_name      = "HR"
  email          = "alice-hr-${random_id.suffix.hex}@example.com"
  password       = random_password.alice.result
  force_sec_auth = false
  administrator          = false
  active = true
}

resource "ionoscloud_group" "object_access" {
  name = "object-access"
  s3_privilege = true
  user_ids = [
    ionoscloud_user.alice.id,
    ionoscloud_user.bob.id
  ]
}

resource "ionoscloud_user" "bob" {
  first_name     = "Bob"
  last_name      = "Sales"
  email          = "bob-sales-${random_id.suffix.hex}@example.com"
  password       = random_password.bob.result
  force_sec_auth = false
  administrator          = false
  active = true
}

resource "ionoscloud_s3_key" "alice" {
  user_id = ionoscloud_user.alice.id
  active  = true
}

resource "ionoscloud_s3_key" "bob" {
  user_id = ionoscloud_user.bob.id
  active  = true
}

resource "ionoscloud_s3_bucket" "test" {
  name   = "iam-test-${random_id.suffix.hex}"
  region = "eu-central-4"
}
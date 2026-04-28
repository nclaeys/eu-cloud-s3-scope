# Fine-grained S3 Access Control on EU Cloud Providers

This repository tests how European S3-compatible cloud providers support fine-grained,
prefix-level object access control. Each provider is tested with both available mechanisms:
**IAM policies** (user/role-level) and **bucket policies** (resource-level).

## Scenario

Two service accounts share a single bucket and must be isolated to their own prefix:

| User | Team | Allowed prefix |
|------|------|----------------|
| Alice | HR | `hr/*` |
| Bob | Sales | `sales/*` |

Each test module provisions the users, keys, bucket, and the access control configuration
for that combination of provider and mechanism.

## Repository Structure

```
<provider>/
  iam-policy/     # Access control via user/role-level IAM policies
  bucket-policy/  # Access control via S3 bucket policies
```

## Provider Support Matrix

| Provider     | IAM policy (prefix-level) | Bucket policy | Notes                                                                                                                                                                              |
|--------------|---------------------------|---------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Exoscale** | Yes                       | Yes (via IAM) | IAM uses CEL expressions; no separate bucket policy resource — bucket-scoping is done by adding a `parameters.bucket ==` condition to the IAM role policy                          |
| **OVHcloud** | Yes                       | No            | Standard AWS IAM JSON attached per user; bucket policies are not supported                                                                                                         |
| **Scaleway** | No                        | Yes           | IAM policies are project-scoped only — prefix restrictions require a bucket policy with `SCW` principal format                                                                     |
| **IONOS**    | No                        | Yes           | No user-level IAM policies for S3; all access control must go through bucket policies                                                                                              |
| **UpCloud**  | Yes                       | No            | Create distinct MOS policies that you can attach to the correct user. Alternative is predefined `ECSS3ReadOnlyAccess` set attached per user (coarse-grained, whole-service scope) |

## Mechanisms

### IAM policies
Policies attached to a user or role identity. Where supported at prefix level, each service
account is denied access to the other team's prefix at the identity layer, regardless of
which bucket they access.

### Bucket policies
Policies attached to the bucket resource. The bucket itself enforces which principals may
access which prefixes. This is the standard fallback when IAM cannot express prefix-level
conditions.

## Terraform

Each module is self-contained with its own `variables.tf` and `outputs.tf`. Provider
credentials are passed via input variables or environment variables as documented in the
module comments. The `aws` provider (pointed at the provider's S3-compatible endpoint)
is used where a native Terraform resource for bucket/IAM management does not exist.

```bash
cd <provider>/<mechanism>
terraform init
terraform apply
```

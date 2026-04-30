# Fine-grained S3 Access Control on EU Cloud Providers

This repository tests how European S3-compatible cloud providers support fine-grained,
object access control. Each provider is tested with both available mechanisms:
**IAM policies** (user/role-level) and **bucket policies** (resource-level with user reference).

## Scenario

Two service accounts share a single bucket and must be isolated to their own prefix:

| User  | Team  | Allowed prefix |
|-------|-------|----------------|
| Alice | HR    | `hr/*`         |
| Bob   | Sales | `sales/*`      |

Each test module provisions the users, keys, bucket, and the access control configuration
for that combination of provider and mechanism.

## Repository Structure

```
<provider>/
  iam-policy/     # Access control via user/role-level IAM policies
  bucket-policy/  # Access control via S3 bucket policies
demo.py           # python script to validate whether the permissions are correct
```

## Provider Support Matrix

| Provider     | IAM policy (prefix-level) | Bucket policy (user reference) | STS support (temp credentials) | Notes                                                                                                                                                        |
|--------------|---------------------------|--------------------------------|--------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Exoscale** | Yes                       | No                             | No                             | IAM uses CEL expressions; general bucket policies exist, but no user parameter supported                                                                     |
| **OVHcloud** | Yes                       | No                             | No                             | Standard AWS IAM JSON attached per user; bucket policies are not supported                                                                                   |
| **Scaleway** | No                        | Yes                            | No                             | IAM policies are coarse-scoped only, prefix restrictions achieved with extra bucket policy with `SCW` principal format                                       |
| **IONOS**    | No                        | Yes                            | No*                            | No user-level IAM policies for S3; all access control must go through bucket policies                                                                        |
| **UpCloud**  | Yes                       | No                             | No*                            | Create distinct MOS policies that you can attach to the correct user. Alternative is predefined `ECSS3ReadOnlyAccess` set attached per user (coarse-grained) |


\* They do support pre-signed urls for temporary access, but that is a different usecase and not as generic as STS.

## Test permissions
Run the demo script as follows:
```bash
python demo.py --provider <provider>/<iam-policy|bucket-policy>
```

Note: for Upcloud, you need to add the `--payload-signing` flag to make sure boto3 uses the correct signature version (v4) for the S3 requests.

## Mechanisms

### IAM policies
Policies attached to a user or role identity. We are interested in detailed policies that can express bucket prefix-level conditions.

### Bucket policies
Policies attached to the bucket resource. The bucket itself enforces which principals may
access which prefixes. This is the standard fallback when IAM cannot express prefix-level
conditions.

## OpenTofu

Each module is self-contained with its own `variables.tf` and `outputs.tf`. Provider
credentials are passed via input variables or environment variables as documented in the
module comments. The `aws` provider (pointed at the provider's S3-compatible endpoint)
is used where a native OpenTofu resource for bucket/IAM management does not exist.

```bash
cd <provider>/<mechanism>
tofu init
tofu apply
```

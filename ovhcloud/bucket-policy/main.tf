# OVHcloud bucket policy test — NOT SUPPORTED.
#
# OVHcloud does not support S3 bucket policies on their Object Storage.
# Feature request: https://github.com/ovh/public-cloud-roadmap/issues/260
terraform {
  required_providers {}
}

output "not_supported" {
  value = "OVHcloud does not support S3 bucket policies. Use ../iam-policy/ instead."
}

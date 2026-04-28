# UpCloud bucket policy test — NOT SUPPORTED.
#
# UpCloud MOS has no S3 bucket policy mechanism. The only access control available
# is attaching predefined permission sets to users via upcloud_managed_object_storage_user_policy,
# which is identical to what iam-policy/ does. There is no distinct bucket-policy
# concept and no Principal support for per-user prefix isolation.
#
# See ../iam-policy/ for the working (coarse-grained) implementation.

terraform {
  required_providers {}
}

output "not_supported" {
  value = "UpCloud MOS does not support S3 bucket policies. Use ../iam-policy/ instead."
}

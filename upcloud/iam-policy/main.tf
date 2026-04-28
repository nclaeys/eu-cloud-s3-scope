# UpCloud IAM policy test.
# UpCloud Managed Object Storage (MOS) uses per-user IAM policies attached to
# service users within the MOS instance. Each user gets an access key pair.
#
# LIMITATION: UpCloud's documented IAM policies use predefined permission sets
# (ECSS3FullAccess, ECSS3ReadOnlyAccess) at the bucket level. Prefix-level
# restrictions within a bucket via IAM are not clearly documented.
#
# This test sets up the closest available approximation: separate users per team
# with ReadWrite access scoped to their own bucket. If UpCloud supports custom
# inline policies with prefix conditions, replace the policy JSON below accordingly.

terraform {
  required_providers {
    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "upcloud" { # We use the UPCLOUD_TOKEN emv var for authentication
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "upcloud_managed_object_storage" "this" {
  name              = "iam-test-${random_id.suffix.hex}"
  region            = var.upcloud_region
  configured_status = "started"

  # needed to get the endpoint, needed for aws s3
  network {
    family = "IPv4"
    name   = "my-public-network"
    type   = "public"
  }
}

# MOS service users — each user represents Alice (HR) and Bob (Sales).
resource "upcloud_managed_object_storage_user" "alice" {
  service_uuid = upcloud_managed_object_storage.this.id
  username     = "alice-hr"
}

resource "upcloud_managed_object_storage_user" "bob" {
  service_uuid = upcloud_managed_object_storage.this.id
  username     = "bob-sales"
}

resource "upcloud_managed_object_storage_user_access_key" "alice" {
  service_uuid = upcloud_managed_object_storage.this.id
  username     = upcloud_managed_object_storage_user.alice.username
  status       = "Active"
}

resource "upcloud_managed_object_storage_user_access_key" "bob" {
  service_uuid = upcloud_managed_object_storage.this.id
  username     = upcloud_managed_object_storage_user.bob.username
  status       = "Active"
}

resource "upcloud_managed_object_storage_bucket" "bucket" {
  service_uuid = upcloud_managed_object_storage.this.id
  name         =  "bp-test-${random_id.suffix.hex}"
}

resource "upcloud_managed_object_storage_user_policy" "alice" {
  username     = upcloud_managed_object_storage_user.alice.username
  service_uuid = upcloud_managed_object_storage.this.id
  name         = upcloud_managed_object_storage_policy.hr_permissions.name
}

resource "upcloud_managed_object_storage_user_policy" "bob" {
  username     = upcloud_managed_object_storage_user.bob.username
  service_uuid = upcloud_managed_object_storage.this.id
  name         = upcloud_managed_object_storage_policy.sales_permissions.name
}

resource "upcloud_managed_object_storage_policy" "hr_permissions" {
  name         = "HrPermissions"
  description  = "Give permissions to HR data"
  document     = urlencode(jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}/hr/*"
      }
    ]
  }))
  service_uuid = upcloud_managed_object_storage.this.id
}

resource "upcloud_managed_object_storage_policy" "sales_permissions" {
  name         = "SalesPermissions"
  description  = "Give permissions to Sales data"
  document     = urlencode(jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${upcloud_managed_object_storage_bucket.bucket.name}/sales/*"
      }
    ]
  }))
  service_uuid = upcloud_managed_object_storage.this.id
}
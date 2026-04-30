# OVHcloud IAM policy test.
# OVHcloud uses user-level S3 policies (standard AWS IAM JSON attached to each user).
terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.13"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "ovh" {
  endpoint           = var.ovh_endpoint
  # We extract the OVH_CONSUMER_KEY, OVH_APPLICATION_KEY, and OVH_APPLICATION_SECRET from environment variables for authentication.
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "ovh_cloud_project_user" "alice" {
  service_name = var.ovh_cloud_project_id
  description  = "Alice HR"
  role_name    = "objectstore_operator"
}

resource "ovh_cloud_project_user" "bob" {
  service_name = var.ovh_cloud_project_id
  description  = "Bob Sales"
  role_name    = "objectstore_operator"
}

resource "ovh_cloud_project_user_s3_credential" "alice" {
  service_name = var.ovh_cloud_project_id
  user_id      = ovh_cloud_project_user.alice.id
}

resource "ovh_cloud_project_user_s3_credential" "bob" {
  service_name = var.ovh_cloud_project_id
  user_id      = ovh_cloud_project_user.bob.id
}

resource "ovh_cloud_project_storage" "storage" {
  service_name = var.ovh_cloud_project_id
  region_name = "GRA"
  name = "iam-test-${random_id.suffix.hex}"
  versioning = {
    status = "disabled"
  }
}

# S3 user policies: standard AWS IAM JSON restricting each user to their prefix.
resource "ovh_cloud_project_user_s3_policy" "alice" {
  service_name = var.ovh_cloud_project_id
  user_id      = ovh_cloud_project_user.alice.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${ovh_cloud_project_storage.storage.name}"
        Condition = {
          StringLike = { "s3:prefix" = ["hr/*"] }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${ovh_cloud_project_storage.storage.name}/hr/*"
      }
    ]
  })
}

resource "ovh_cloud_project_user_s3_policy" "bob" {
  service_name = var.ovh_cloud_project_id
  user_id      = ovh_cloud_project_user.bob.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${ovh_cloud_project_storage.storage.name}"
        Condition = {
          StringLike = { "s3:prefix" = ["sales/*"] }
        }
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${ovh_cloud_project_storage.storage.name}/sales/*"
      }
    ]
  })
}

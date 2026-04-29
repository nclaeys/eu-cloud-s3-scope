terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "scaleway" {
  alias = "tmp"
}

resource scaleway_account_project "project" {
  provider = scaleway.tmp
  name     = "bucket-policy-test"
  organization_id = var.organisation_id
}

provider "scaleway" {
  project_id = scaleway_account_project.project.id
  region     = var.scw_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "scaleway_iam_application" "alice" {
  name        = "alice-hr-${random_id.suffix.hex}"
  description = "HR team service account"
  organization_id = var.organisation_id
}

resource "scaleway_iam_application" "bob" {
  name        = "bob-sales-${random_id.suffix.hex}"
  description = "Sales team service account"
  organization_id = var.organisation_id
}

resource "scaleway_iam_api_key" "alice" {
  application_id = scaleway_iam_application.alice.id
  default_project_id = scaleway_account_project.project.id
  description    = "Alice HR S3 key"
}

resource "scaleway_iam_api_key" "bob" {
  application_id = scaleway_iam_application.bob.id
  default_project_id = scaleway_account_project.project.id
  description    = "Bob Sales S3 key"
}

resource "scaleway_object_bucket" "test" {
  project_id = scaleway_account_project.project.id
  name   = "bp-test-${random_id.suffix.hex}"
  region = var.scw_region
}

# You need to create IAM policy for the user, otherwise he won't be able to do anything, even if bucket policy allows it.
# You need to use the predefined permission sets: https://www.scaleway.com/en/docs/iam/reference-content/permission-sets/
resource "scaleway_iam_policy" "alice" {
  name            = "alice-hr-policy-${random_id.suffix.hex}"
  application_id  = scaleway_iam_application.alice.id
  rule {
    organization_id          = var.organisation_id
    permission_set_names = ["ObjectStorageBucketsRead", "ObjectStorageObjectsRead", "ObjectStorageObjectsWrite", "ObjectStorageObjectsDelete"]
  }
}

resource "scaleway_iam_policy" "bob" {
  name            = "bob-sales-policy-${random_id.suffix.hex}"
  application_id  = scaleway_iam_application.bob.id
  rule {
    organization_id          = var.organisation_id
    permission_set_names = ["ObjectStorageBucketsRead", "ObjectStorageObjectsRead", "ObjectStorageObjectsWrite", "ObjectStorageObjectsDelete"]
  }
}

resource "scaleway_object_bucket_policy" "test" {
  bucket = scaleway_object_bucket.test.name
  policy = jsonencode({
    Version = "2023-04-17"
    Statement = [
      {
        Sid       = "AliceListBucket"
        Effect    = "Allow"
        Principal = { SCW = "application_id:${scaleway_iam_application.alice.id}" }
        Action    = ["s3:ListBucket"]
        Resource  = scaleway_object_bucket.test.name
        Condition = { StringLike = { "s3:prefix" = ["hr/*"] } }
      },
      {
        Sid       = "BobListBucket"
        Effect    = "Allow"
        Principal = { SCW = "application_id:${scaleway_iam_application.bob.id}" }
        Action    = ["s3:ListBucket"]
        Resource  = scaleway_object_bucket.test.name
        Condition = { StringLike = { "s3:prefix" = ["sales/*"] } }
      },
      {
        Sid       = "AliceHRReadWrite"
        Effect    = "Allow"
        Principal = { SCW = "application_id:${scaleway_iam_application.alice.id}" }
        Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource  = ["${scaleway_object_bucket.test.name}/hr/*"]
      },
      {
        Sid       = "BobSalesReadWrite"
        Effect    = "Allow"
        Principal = { SCW = "application_id:${scaleway_iam_application.bob.id}" }
        Action    = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource  = ["${scaleway_object_bucket.test.name}/sales/*"]
      }
    ]
  })
}


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

data "ionoscloud_contracts" "current" {}

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

resource "ionoscloud_user" "bob" {
  first_name     = "Bob"
  last_name      = "Sales"
  email          = "bob-sales-${random_id.suffix.hex}@example.com"
  password       = random_password.bob.result
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

# Make sure you set the env variable: IONOS_S3_KEY_CREATION_RETRY=true, otherwise the S3 key creation will fail often.
resource "ionoscloud_s3_key" "alice" {
  user_id = ionoscloud_user.alice.id
  active  = true
}

resource "ionoscloud_s3_key" "bob" {
  user_id = ionoscloud_user.bob.id
  active  = true
}

resource "ionoscloud_s3_bucket" "test" {
  name   = "bp-test-${random_id.suffix.hex}"
  region = "eu-central-4"
}

# Principal ARN format for IONOS: arn:aws:iam:::user/<contractNumber>:<userUUID>
resource "ionoscloud_s3_bucket_policy" "test" {
  bucket = ionoscloud_s3_bucket.test.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AliceListBucket"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam:::user/${data.ionoscloud_contracts.current.contracts[0].contract_number}:${ionoscloud_user.alice.id}"
        }
        Action    = ["s3:ListBucket"]
        Resource  = ["arn:aws:s3:::${ionoscloud_s3_bucket.test.name}"]
      },
      {
        Sid    = "AliceHRReadWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam:::user/${data.ionoscloud_contracts.current.contracts[0].contract_number}:${ionoscloud_user.alice.id}"
        }
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${ionoscloud_s3_bucket.test.name}/hr/*"]
      },
      {
        Sid    = "BobListBucket"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam:::user/${data.ionoscloud_contracts.current.contracts[0].contract_number}:${ionoscloud_user.bob.id}"
        }
        Action    = ["s3:ListBucket"]
        Resource  = ["arn:aws:s3:::${ionoscloud_s3_bucket.test.name}"]
      },
      {
        Sid    = "BobSalesReadWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam:::user/${data.ionoscloud_contracts.current.contracts[0].contract_number}:${ionoscloud_user.bob.id}"
        }
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::${ionoscloud_s3_bucket.test.name}/sales/*"]
      }
    ]
  })
}

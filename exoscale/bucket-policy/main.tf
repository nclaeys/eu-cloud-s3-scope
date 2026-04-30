# Exoscale does not have a bucket policy.
# Exoscale has bucket policies for generic restrictions. They support key, but not the individual user as a parameter.
# Full details of the CEL expressions can be found at: https://community.exoscale.com/product/iam/how-to/policy-guide/#cel-bindings
# User based access is done using iam policies though

terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.68"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.43"
    }
  }
}

provider "aws" {
  endpoints {
    s3 = "https://sos-${var.exoscale_zone}.exo.io"
  }

  region     = var.exoscale_zone
  access_key = var.exoscale_api_key
  secret_key = var.exoscale_api_secret

  # Disable AWS-specific features: https://community.exoscale.com/community/storage/terraform/
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "exoscale" {
    key = var.exoscale_api_key
    secret = var.exoscale_api_secret
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "test" {
  bucket = "bp-test-${random_id.suffix.hex}"
}

resource "exoscale_iam_role" "alice" {
  name        = "alice-hr-${random_id.suffix.hex}"
  description = "Alice HR — bucket + prefix scoped via IAM role policy"
  editable    = true
}

resource "exoscale_iam_api_key" "alice" {
  name    = "alice-hr-key-${random_id.suffix.hex}"
  role_id = exoscale_iam_role.alice.id
}

resource "exoscale_iam_role" "bob" {
  name        = "bob-sales-${random_id.suffix.hex}"
  description = "Bob Sales — bucket + prefix scoped via IAM role policy"
  editable    = true
}

resource "exoscale_iam_api_key" "bob" {
  name    = "bob-sales-key-${random_id.suffix.hex}"
  role_id = exoscale_iam_role.bob.id
}

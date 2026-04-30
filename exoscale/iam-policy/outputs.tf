output "s3_endpoint" {
  value = "https://sos-${var.exoscale_zone}.exo.io"
}

output "bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "alice_access_key_id" {
  value     = exoscale_iam_api_key.alice.key
  sensitive = true
}

output "alice_secret_key" {
  value     = exoscale_iam_api_key.alice.secret
  sensitive = true
}

output "bob_access_key_id" {
  value     = exoscale_iam_api_key.bob.key
  sensitive = true
}

output "bob_secret_key" {
  value     = exoscale_iam_api_key.bob.secret
  sensitive = true
}

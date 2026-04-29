output "s3_endpoint" {
  value = "https://s3.${var.scw_region}.scw.cloud"
}

output "bucket_name" {
  value = scaleway_object_bucket.test.name
}

output "alice_access_key_id" {
  value     = scaleway_iam_api_key.alice.access_key
  sensitive = true
}

output "alice_secret_key" {
  value     = scaleway_iam_api_key.alice.secret_key
  sensitive = true
}

output "bob_access_key_id" {
  value     = scaleway_iam_api_key.bob.access_key
  sensitive = true
}

output "bob_secret_key" {
  value     = scaleway_iam_api_key.bob.secret_key
  sensitive = true
}

output "s3_endpoint" {
  value = "https://s3.eu-central-4.ionoscloud.com"
}

output "bucket_name" {
  value = ionoscloud_s3_bucket.test.name
}

output "alice_access_key_id" {
  value     = ionoscloud_s3_key.alice.id
  sensitive = true
}

output "alice_secret_key" {
  value     = ionoscloud_s3_key.alice.secret_key
  sensitive = true
}

output "bob_access_key_id" {
  value     = ionoscloud_s3_key.bob.id
  sensitive = true
}

output "bob_secret_key" {
  value     = ionoscloud_s3_key.bob.secret_key
  sensitive = true
}

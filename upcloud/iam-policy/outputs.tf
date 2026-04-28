output "s3_endpoint" {
  value = "https://${tolist(upcloud_managed_object_storage.this.endpoint)[0].domain_name}"
}

output "bucket_name" {
  value = upcloud_managed_object_storage_bucket.bucket.name
}

output "alice_access_key_id" {
  value     = upcloud_managed_object_storage_user_access_key.alice.access_key_id
  sensitive = true
}

output "alice_secret_key" {
  value     = upcloud_managed_object_storage_user_access_key.alice.secret_access_key
  sensitive = true
}

output "bob_access_key_id" {
  value     = upcloud_managed_object_storage_user_access_key.bob.access_key_id
  sensitive = true
}

output "bob_secret_key" {
  value     = upcloud_managed_object_storage_user_access_key.bob.secret_access_key
  sensitive = true
}

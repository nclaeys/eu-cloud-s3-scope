output "s3_endpoint" {
  value = "https://s3.${lower(var.ovh_region)}.io.cloud.ovh.net"
}

output "bucket_name" {
  value = ovh_cloud_project_storage.storage.name
}

output "alice_access_key_id" {
  value     = ovh_cloud_project_user_s3_credential.alice.access_key_id
  sensitive = true
}

output "alice_secret_key" {
  value     = ovh_cloud_project_user_s3_credential.alice.secret_access_key
  sensitive = true
}

output "bob_access_key_id" {
  value     = ovh_cloud_project_user_s3_credential.bob.access_key_id
  sensitive = true
}

output "bob_secret_key" {
  value     = ovh_cloud_project_user_s3_credential.bob.secret_access_key
  sensitive = true
}

variable "ovh_endpoint" {
  description = "OVH API endpoint (e.g. ovh-eu)"
  default     = "ovh-eu"
}

variable "ovh_cloud_project_id" {
  description = "OVH Cloud project ID (service name)"
  default = "93325710cc8b45bf9a1074e55aa9243c"
}

variable "ovh_region" {
  description = "OVH region for S3-compatible storage"
  default     = "GRA"
}

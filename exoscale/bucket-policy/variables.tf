variable "exoscale_api_key" {
  description = "Exoscale API key (IAM → API keys, must have iam/sos permissions)"
  sensitive   = true
}

variable "exoscale_api_secret" {
  description = "Exoscale API secret"
  sensitive   = true
}

variable "exoscale_zone" {
  description = "Exoscale zone"
  default     = "ch-gva-2"
}

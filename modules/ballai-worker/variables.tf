variable "name_prefix" {
  type        = string
  description = "Prefix for resource names."
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID."
}

variable "worker_secrets" {
  type        = map(string)
  description = "Map of secret name to value for the ballai-api Worker."
  sensitive   = true
  default     = {}
}

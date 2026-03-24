variable "name_prefix" {
  type        = string
  description = "Prefix for resource names."
}

variable "account_id" {
  type        = string
  description = "Cloudflare account ID."
}

variable "worker_secret_names" {
  type        = set(string)
  description = "Set of secret names to manage on the ballai-api Worker. Non-sensitive so it can be used in for_each."
  default     = []
}

variable "worker_secrets" {
  type        = map(string)
  description = "Map of secret name to value. Must contain entries for all names in worker_secret_names."
  sensitive   = true
  default     = {}
}

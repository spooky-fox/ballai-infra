variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID (set via TF_VAR_cloudflare_account_id or terraform.tfvars)."
  default     = "00000000000000000000000000000000"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for future resource names."
  default     = "ballai"
}

# Optional: wire explicitly instead of env-only token
# variable "cloudflare_api_token" {
#   type        = string
#   description = "Cloudflare API token"
#   sensitive   = true
# }

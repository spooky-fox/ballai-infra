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

variable "aws_region" {
  type        = string
  description = "AWS region for infrastructure resources."
  default     = "us-west-2"
}

variable "enable_github_actions_runners" {
  type        = bool
  description = "Enable AWS CodeBuild managed GitHub Actions runner infrastructure."
  default     = true
}

variable "github_owner" {
  type        = string
  description = "GitHub owner/org where runner projects are used."
  default     = "spooky-fox"
}

variable "github_runner_group_id" {
  type        = number
  description = "GitHub runner group id used for registration."
  default     = 1
}

# --- Cloudflare Worker Secrets ---

variable "worker_auth_secret" {
  type      = string
  sensitive = true
  default   = ""
}

variable "together_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tavily_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "kagi_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "serpapi_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "google_service_account_email" {
  type      = string
  sensitive = true
  default   = ""
}

variable "google_service_account_private_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tiller_spreadsheet_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tiller_personal_spreadsheet_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "tiller_business_spreadsheet_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "genius_scan_folder_id" {
  type      = string
  sensitive = true
  default   = ""
}

variable "duffel_api_token" {
  type      = string
  sensitive = true
  default   = ""
}

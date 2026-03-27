variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID (set via TF_VAR_cloudflare_account_id or terraform.tfvars)."

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.cloudflare_account_id))
    error_message = "Must be a 32-character hex Cloudflare account ID."
  }
}

variable "domain" {
  type        = string
  description = "Primary zone / site domain."
  default     = "lanzo.app"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]+\\.[a-z]{2,}$", var.domain))
    error_message = "Must be a valid domain name."
  }
}

variable "pages_project_name" {
  type        = string
  description = "Cloudflare Pages project name."
  default     = "lanzo-web"
}

variable "formspree_form_id" {
  type        = string
  description = "Formspree form ID for waitlist (e.g. from https://formspree.io/f/<id>)."
  default     = "xgonnjjj"
  sensitive   = false
}

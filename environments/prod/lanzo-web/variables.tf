variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID (set via TF_VAR_cloudflare_account_id or terraform.tfvars)."
}

variable "domain" {
  type        = string
  description = "Primary zone / site domain."
  default     = "lanzo.app"
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

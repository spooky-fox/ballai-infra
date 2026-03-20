variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID (set via TF_VAR_cloudflare_account_id or terraform.tfvars)."
  default     = "3ab81ea42c5731a9ea2fb65f9bf89548"
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
  default     = ""
  sensitive   = false
}

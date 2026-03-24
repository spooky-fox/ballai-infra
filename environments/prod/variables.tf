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

variable "enable_github_actions_codebuild_backup" {
  type        = bool
  description = <<-EOT
    Provision additional Linux CodeBuild GHA runner projects for the same GitHub repos with distinct
    runs-on labels (e.g. ballai-backup). Use when you want a hot-standby pool or to test larger
    compute without changing primary project names. Default false.
  EOT
  default     = false
}

variable "github_actions_codebuild_extra_repositories" {
  type = map(object({
    repository_name = string
    description     = optional(string, "")
    compute_type    = optional(string, "BUILD_GENERAL1_MEDIUM")
    image           = optional(string, "aws/codebuild/amazonlinux-x86_64-standard:5.0")
    environment     = optional(string, "LINUX_CONTAINER")
  }))
  description = <<-EOT
    Optional extra CodeBuild GHA runner projects keyed by short name (becomes "<name_prefix>-<key>").
    Use for macOS (environment type MAC_ARM, region-specific image/compute per AWS docs), Windows, or
    alternate Linux images. Default {} — add entries when ready; verify CodeBuild + GitHub OAuth and
    any reserved fleet requirements before apply.
  EOT
  default     = {}
}

# Optional: wire explicitly instead of env-only token
# variable "cloudflare_api_token" {
#   type        = string
#   description = "Cloudflare API token"
#   sensitive   = true
# }

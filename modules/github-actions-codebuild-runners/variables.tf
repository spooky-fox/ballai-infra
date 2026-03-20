variable "name_prefix" {
  description = "Prefix for CodeBuild runner project names."
  type        = string
}

variable "github_owner" {
  description = "GitHub owner/org for repositories."
  type        = string
}

variable "repositories" {
  description = "Repository runner configuration keyed by short name."
  type = map(object({
    repository_name = string
    description     = optional(string, "")
    compute_type    = optional(string, "BUILD_GENERAL1_MEDIUM")
    image           = optional(string, "aws/codebuild/amazonlinux-x86_64-standard:5.0")
    environment     = optional(string, "LINUX_CONTAINER")
  }))
}

variable "runner_group_id" {
  description = "GitHub runner group ID for JIT registration."
  type        = number
  default     = 1
}

variable "org_registration_name" {
  description = "Optional GitHub organization name for org-level runner registration."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention for CodeBuild runner projects."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Common AWS tags."
  type        = map(string)
  default     = {}
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for queue and build duration."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "SNS or other alarm action ARNs for CloudWatch alarms."
  type        = list(string)
  default     = []
}

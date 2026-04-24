variable "worker_url" {
  type        = string
  description = "HTTPS URL of the Cloudflare Worker that acts as the OIDC identity provider (e.g. https://ballai-api.ballai.workers.dev)."

  validation {
    condition     = can(regex("^https://", var.worker_url))
    error_message = "worker_url must start with https://."
  }
}

variable "worker_subject" {
  type        = string
  description = "The 'sub' claim value the Worker will use in JWTs. Must match what the Worker signs."
  default     = "ballai-worker"
}

variable "role_name" {
  type        = string
  description = "Name for the IAM role that the Worker assumes."
  default     = "ballai-worker-bedrock"
}

variable "bedrock_model_arns" {
  type        = list(string)
  description = "ARNs of Bedrock foundation models and inference profiles the role can invoke."
  default = [
    "arn:aws:bedrock:us-west-2::foundation-model/cohere.rerank-v3-5:0",
    "arn:aws:bedrock:*::foundation-model/cohere.embed-v4:0",
    "arn:aws:bedrock:*:*:inference-profile/us.cohere.embed-v4:0",
  ]
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration in seconds for the assumed role (1-12 hours)."
  default     = 3600
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to IAM resources."
  default     = {}
}

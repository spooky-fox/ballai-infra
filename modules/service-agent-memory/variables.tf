variable "name" {
  type    = string
  default = "agent-memory"
}

variable "cpu" {
  type    = number
  default = 2048
}

variable "memory" {
  type    = number
  default = 4096
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "image" {
  type    = string
  default = ""
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "host_header" {
  type    = string
  default = "memory.spookyfox.com"
}

variable "listener_priority" {
  type    = number
  default = 100
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "alert_email" {
  type    = string
  default = "ballew@spookyfox.com"
}

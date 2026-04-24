variable "name" {
  type    = string
  default = "phoenix"
}

variable "cpu" {
  type    = number
  default = 1024
}

variable "memory" {
  type    = number
  default = 2048
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "image" {
  type    = string
  default = "arizephoenix/phoenix:version-13.15.0"
}

variable "health_check_path" {
  type    = string
  default = "/healthz"
}

variable "host_header" {
  type    = string
  default = "phoenix.spookyfox.com"
}

variable "listener_priority" {
  type    = number
  default = 200
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

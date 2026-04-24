variable "name" {
  type    = string
  default = "spookyfox-shared"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    { cidr = "10.0.1.0/24", az = "us-west-2a" },
    { cidr = "10.0.2.0/24", az = "us-west-2b" },
  ]
}

variable "private_subnets" {
  type = list(object({
    cidr = string
    az   = string
  }))
  default = [
    { cidr = "10.0.10.0/24", az = "us-west-2a" },
  ]
}

variable "neo4j_instance_type" {
  type    = string
  default = "t4g.large"
}

variable "neo4j_ami" {
  type    = string
  default = "ami-0c0da15b60f7d5612"
}

variable "neo4j_volume_size" {
  type    = number
  default = 20
}

variable "acm_domain" {
  type    = string
  default = "*.spookyfox.com"
}

variable "acm_san" {
  type    = list(string)
  default = ["*.spookyfox.com", "spookyfox.com"]
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 zone ID for spookyfox.com (in chatresearch account)"
  default     = "Z0174990BOLSPIKZLIBQ"
}

variable "ssm_parameters" {
  type = map(object({
    type  = string
    value = string
  }))
  default   = {}
  sensitive = true
}

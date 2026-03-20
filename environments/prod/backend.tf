terraform {
  backend "s3" {
    bucket  = "together-terraform-state"
    key     = "prod/us-west-2/ballai/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

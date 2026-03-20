terraform {
  backend "s3" {
    bucket  = "terraform-spookyfox"
    key     = "shared/ballai/prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

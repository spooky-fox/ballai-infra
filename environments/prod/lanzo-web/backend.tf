terraform {
  backend "s3" {
    bucket  = "together-terraform-state"
    key     = "prod/us-west-2/lanzo-web/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  # Prefer CLOUDFLARE_API_TOKEN in environment (e.g. GitHub Actions secrets).
  # api_token = var.cloudflare_api_token
}

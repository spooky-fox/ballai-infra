terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.22"
    }
  }
}

locals {
  worker_name  = "${var.name_prefix}-api"
  secret_names = nonsensitive(toset(keys(var.worker_secrets)))
}

resource "cloudflare_workers_secret" "secrets" {
  for_each = local.secret_names

  account_id  = var.account_id
  script_name = local.worker_name
  name        = each.value
  secret_text = var.worker_secrets[each.value]
}

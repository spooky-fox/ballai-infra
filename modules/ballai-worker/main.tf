terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

locals {
  worker_name = "ballai-api"
}

# TODO(#15): cloudflare_workers_secret was removed in provider v5.
# Secrets must now be managed via cloudflare_workers_script bindings
# (type = "secret_text") or the Secrets Store (cloudflare_secrets_store_secret,
# pending terraform support). Re-enable once a v5-compatible approach is chosen.
#
# resource "cloudflare_workers_secret" "secrets" {
#   for_each = var.worker_secret_names
#
#   account_id  = var.account_id
#   script_name = local.worker_name
#   name        = each.value
#   secret_text = var.worker_secrets[each.value]
# }

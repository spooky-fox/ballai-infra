locals {
  contact_email = "ballew@spookyfox.com"

  pages_deploy_config = {
    compatibility_date  = "2026-03-16"
    compatibility_flags = ["nodejs_compat"]
    fail_open           = true
    usage_model         = "standard"
    env_vars = var.formspree_form_id != "" ? {
      NEXT_PUBLIC_FORMSPREE_FORM_ID = {
        type  = "plain_text"
        value = var.formspree_form_id
      }
    } : {}
  }
}

# --- Zone ---
# Moves DNS to Cloudflare (historically from Route53).
# After apply, ensure registrar nameservers match output nameservers.

resource "cloudflare_zone" "lanzo" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain
  type = "full"
}

# --- Pages Project ---
# If the project already exists (created via API), import before first apply:
#   terraform import cloudflare_pages_project.lanzo 'ACCOUNT_ID/lanzo-web'

resource "cloudflare_pages_project" "lanzo" {
  account_id        = var.cloudflare_account_id
  name              = var.pages_project_name
  production_branch = "main"

  build_config = {
    build_command   = "npx @opennextjs/cloudflare build"
    destination_dir = ".open-next/assets"
    root_dir        = ""
  }

  deployment_configs = {
    production = local.pages_deploy_config
    preview    = local.pages_deploy_config
  }
}

# --- Custom Domain ---
# Attaches apex domain to the Pages project.

resource "cloudflare_pages_domain" "apex" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.lanzo.name
  name         = var.domain
}

# --- DNS Records ---
# CNAME at apex (Cloudflare flattens this automatically).

resource "cloudflare_dns_record" "apex" {
  zone_id = cloudflare_zone.lanzo.id
  name    = "@"
  type    = "CNAME"
  content = "${var.pages_project_name}.pages.dev"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = cloudflare_zone.lanzo.id
  name    = "www"
  type    = "CNAME"
  content = "${var.pages_project_name}.pages.dev"
  proxied = true
  ttl     = 1
}

# --- Search engine verification ---

resource "cloudflare_dns_record" "google_verification" {
  zone_id = cloudflare_zone.lanzo.id
  name    = "@"
  type    = "TXT"
  content = "google-site-verification=VqBWAYdQtJN_gzSDxa6kiYOWn6nva5h03tuSv212y2E"
  ttl     = 3600
}

# --- Email routing ---

# Email routing may already be enabled in the dashboard; settings resource omitted
# because the enable endpoint can return 403 if already enabled.

resource "cloudflare_email_routing_address" "destination" {
  account_id = var.cloudflare_account_id
  email      = local.contact_email
}

locals {
  email_aliases = [
    { name = "hello", address = "hello@lanzo.app" },
    { name = "social", address = "social@lanzo.app" },
    { name = "twitter", address = "twitter@lanzo.app" },
    { name = "instagram", address = "instagram@lanzo.app" },
    { name = "tiktok", address = "tiktok@lanzo.app" },
    { name = "press", address = "press@lanzo.app" },
    { name = "partners", address = "partners@lanzo.app" },
  ]
}

resource "cloudflare_email_routing_rule" "aliases" {
  for_each = { for alias in local.email_aliases : alias.name => alias }

  zone_id = cloudflare_zone.lanzo.id
  name    = "Forward ${each.value.name}@lanzo.app"
  enabled = true

  matchers = [{
    type  = "literal"
    field = "to"
    value = each.value.address
  }]

  actions = [{
    type  = "forward"
    value = [local.contact_email]
  }]
}

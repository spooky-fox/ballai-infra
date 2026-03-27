output "nameservers" {
  description = "Set these as custom nameservers at the registrar for the zone."
  value       = cloudflare_zone.lanzo.name_servers
}

output "zone_id" {
  description = "Cloudflare zone ID for the domain."
  value       = cloudflare_zone.lanzo.id
}

output "zone_status" {
  description = "Activation status of the Cloudflare zone."
  value       = cloudflare_zone.lanzo.status
}

output "pages_domain_status" {
  description = "Status of the Cloudflare Pages custom domain."
  value       = cloudflare_pages_domain.apex.status
}

output "pages_subdomain" {
  description = "Default subdomain assigned by Cloudflare Pages."
  value       = cloudflare_pages_project.lanzo.subdomain
}

output "nameservers" {
  description = "Set these as custom nameservers at the registrar for the zone."
  value       = cloudflare_zone.lanzo.name_servers
}

output "zone_id" {
  value = cloudflare_zone.lanzo.id
}

output "zone_status" {
  value = cloudflare_zone.lanzo.status
}

output "pages_domain_status" {
  value = cloudflare_pages_domain.apex.status
}

output "pages_subdomain" {
  value = cloudflare_pages_project.lanzo.subdomain
}

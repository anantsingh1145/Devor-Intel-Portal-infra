output "fqdn" {
  description = "The domain name records were created for, or null when DNS was skipped."
  value       = length(module.records) > 0 ? var.domain_name : null
}

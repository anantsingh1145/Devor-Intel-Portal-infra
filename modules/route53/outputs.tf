output "fqdn" {
  description = "The domain name the record was created for, or null when DNS was skipped."
  value       = length(aws_route53_record.app) > 0 ? var.domain_name : null
}

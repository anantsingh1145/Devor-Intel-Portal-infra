output "certificate_arn" {
  description = "ARN of the validated ACM certificate, or null when var.domain_name was not set."
  value       = length(module.acm) > 0 ? module.acm[0].acm_certificate_arn : null
}

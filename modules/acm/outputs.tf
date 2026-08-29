output "certificate_arn" {
  description = "ARN of the issued (validated) certificate. Resolving this output is what makes downstream resources wait for validation."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "validation_record" {
  description = "DNS record to create manually at the domain's DNS provider to prove ownership: { name, type, value }."
  value = {
    name  = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_name
    type  = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_type
    value = tolist(aws_acm_certificate.this.domain_validation_options)[0].resource_record_value
  }
}

output "certificate_arn" {
  description = "ARN of the issued (validated) certificate. Resolving this output is what makes downstream resources wait for validation."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

# devor.net's nameservers stay at GoDaddy (not migrated to Route 53), so the
# DNS validation CNAME can't be created by Terraform - it's surfaced via
# outputs.validation_record for manual creation at GoDaddy instead.
#
# aws_acm_certificate_validation blocks here until ACM sees that CNAME and
# issues the certificate, so the first apply after adding this module will
# hang/time out until the record is added and has propagated - that's
# expected, not a bug. Re-running apply once DNS has propagated proceeds.
resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn
}

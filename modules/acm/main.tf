# devor.net's nameservers stay at GoDaddy (not migrated to Route 53), so the
# DNS validation CNAME can't be created by Terraform - it's surfaced via
# outputs.validation_record for manual creation at GoDaddy instead.
#
# Bootstrap this module BEFORE running the full apply (in CI or anywhere
# else), since nothing can pause an unattended apply mid-run for a manual
# DNS step:
#   1. terraform apply -target=module.acm.aws_acm_certificate.this
#   2. terraform output acm_certificate_validation_record -> add that CNAME
#      at GoDaddy, wait for it to resolve (dig <name> CNAME)
#   3. terraform apply (full) - validation now completes in well under the
#      10m timeout below, instead of hanging until it eats the CI job's
#      OIDC session and fails to persist state.
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

  # Default wait is long enough to run past the CI job's ~1h OIDC session
  # (github's aws-actions/configure-aws-credentials), which then fails to
  # persist state on top of the real failure (missing CNAME). Fail fast
  # instead - see the bootstrap sequence note above.
  timeouts {
    create = "10m"
  }
}

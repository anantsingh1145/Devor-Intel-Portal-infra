# Cert covers var.domain_name (www) plus var.root_domain (apex). DNS validation
# records are created in the Route 53 zone (var.zone_id), so no manual DNS step.
# The zone's nameservers must already be delegated at the registrar - see
# dns.tf for the bootstrap sequence.
resource "aws_acm_certificate" "this" {
  domain_name               = var.domain_name
  subject_alternative_names = [var.root_domain]
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for o in aws_acm_certificate.this.domain_validation_options : o.domain_name => o
  }

  zone_id         = var.zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 60
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]

  # Fail fast if the registrar nameservers haven't been switched yet.
  timeouts {
    create = "10m"
  }
}

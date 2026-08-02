# https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest
#
# Created only when var.domain_name is set, so environments without a custom
# domain (e.g. dev) can skip HTTPS/Route53 entirely with no code changes.
module "acm" {
  count = var.domain_name != "" ? 1 : 0

  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name = var.domain_name
  zone_id     = var.zone_id

  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  wait_for_validation       = true

  tags = var.tags
}

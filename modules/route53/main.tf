# https://registry.terraform.io/modules/terraform-aws-modules/route53/aws/latest/submodules/records
#
# Created only when both var.domain_name and var.zone_id are set, so
# environments without a custom domain (e.g. dev) skip DNS entirely.
module "records" {
  count = var.domain_name != "" && var.zone_id != "" ? 1 : 0

  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_id = var.zone_id

  records = [
    {
      name = var.domain_name
      type = "A"
      alias = {
        name                   = var.alb_dns_name
        zone_id                = var.alb_zone_id
        evaluate_target_health = true
      }
    }
  ]
}

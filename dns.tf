# Route 53 hosts devor.net so the apex can ALIAS to the ALB (GoDaddy can't
# CNAME/ALIAS an apex). Registrar stays at GoDaddy; only nameservers move.
#
# Bootstrap (nothing can pause an unattended apply for a manual step):
#   1. terraform apply -target=aws_route53_zone.this
#   2. terraform output name_servers -> set these as the custom nameservers
#      for devor.net at GoDaddy (Domain -> DNS -> Nameservers -> Change)
#   3. wait for delegation: dig +short NS devor.net
#   4. terraform apply (full)
# Before step 2, copy every record GoDaddy serves that must survive (email!)
# into var.extra_dns_records - anything missing from the new zone stops
# resolving the moment nameservers switch.
resource "aws_route53_zone" "this" {
  name = var.root_domain
  tags = local.common_tags

  # Destroying the zone while GoDaddy still delegates to it leaves dangling
  # nameservers someone else could claim. Revert the GoDaddy nameservers
  # first, then remove this guard to delete the zone.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_route53_record" "apex" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.root_domain
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "extra" {
  for_each = var.extra_dns_records

  zone_id = aws_route53_zone.this.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = each.value.records
}

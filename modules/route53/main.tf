# Plain (non-alias) A record, not the terraform-aws-modules registry
# submodule, because that submodule only supports alias records (which point
# at other AWS resources like an ALB by zone_id+dns_name) — there's no ALB in
# this architecture, just a bare IP, which only a plain A record supports.
#
# Created only when both var.domain_name and var.zone_id are set, so
# environments without a custom domain can skip DNS entirely.
#
# The record's value is a placeholder (RFC 5737 TEST-NET address, guaranteed
# non-routable) at creation time — modules/dns_sync's Lambda overwrites it
# with the Fargate task's real public IP within moments of the task starting.
# lifecycle.ignore_changes stops Terraform from "fixing" it back to the
# placeholder on every subsequent plan/apply once the Lambda owns it.
resource "aws_route53_record" "app" {
  count = var.domain_name != "" && var.zone_id != "" ? 1 : 0

  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 60
  records = ["203.0.113.1"]

  lifecycle {
    ignore_changes = [records]
  }
}

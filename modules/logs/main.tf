# No dedicated official registry module for a bare CloudWatch Log Group, so
# this uses the native resource directly, per the "use resources where no
# module fits" rule for this repo.
resource "aws_cloudwatch_log_group" "this" {
  name              = var.name
  retention_in_days = var.retention_in_days
  tags              = var.tags
}

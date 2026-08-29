# No terraform-aws-modules registry module for AWS Budgets, so this uses the
# native resource directly, per the "use resources where no module fits"
# rule for this repo.
#
# Account-wide (no cost_filter) by default — simplest and works immediately.
# If this account ever hosts unrelated work alongside this project, scope it
# to just this project's resources instead by adding a cost_filter on the
# "Project" tag — but that requires activating "Project" as a cost
# allocation tag in the Billing console first (manual step, ~24h to take
# effect), so it's not the default here.
resource "aws_budgets_budget" "this" {
  name        = var.name
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = var.limit_amount
  limit_unit   = var.limit_unit

  dynamic "notification" {
    for_each = toset(var.alert_thresholds_percent)
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = var.notification_emails
    }
  }

  # Extra early warning based on Cost Explorer's forecast for the month, not
  # just spend so far — catches a runaway trajectory before it actually
  # crosses the limit, not just after.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.notification_emails
  }

  tags = var.tags
}

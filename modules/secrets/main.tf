# No official registry module for Secrets Manager fits a simple "N secrets"
# use case, so this uses native resources directly, per the "use resources
# where no module fits" rule for this repo. Driven entirely by var.secret_names
# so adding/removing a secret is a one-line tfvars change, not a code change.
#
# Deliberately does NOT create aws_secretsmanager_secret_version: values are
# set manually outside Terraform (console or `aws secretsmanager
# put-secret-value`), per explicit requirement to never pass secret values
# through code. The task using these secrets will fail to start until each
# one has a value.

resource "aws_secretsmanager_secret" "this" {
  for_each = toset(var.secret_names)

  name                    = "${var.name_prefix}/${each.key}"
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

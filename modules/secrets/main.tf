# No official registry module for Secrets Manager fits a simple "N secrets"
# use case, so this uses native resources directly, per the "use resources
# where no module fits" rule for this repo. Driven entirely by var.secrets so
# adding/removing a secret is a one-line tfvars change, not a code change.

locals {
  # Terraform forbids using a sensitive value as a for_each set, even just for
  # its keys. The key set (env var names like "ANTHROPIC_API_KEY") isn't
  # secret — only the values are — so it's safe to strip sensitivity here;
  # `var.secrets[each.key]` below stays sensitive.
  secret_names = nonsensitive(toset(keys(var.secrets)))
}

resource "aws_secretsmanager_secret" "this" {
  for_each = local.secret_names

  name                    = "${var.name_prefix}/${each.key}"
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secret_names

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = var.secrets[each.key]
}

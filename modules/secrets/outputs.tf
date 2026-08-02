output "secret_arns" {
  description = "Map of secret name => ARN, consumed by the fargate module (container `secrets`) and the iam module (execution role read policy)."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }

  # The ARN alone exists as soon as aws_secretsmanager_secret.this is created,
  # but consumers of this output need an actual value to be readable at that
  # ARN too (ECS resolves `secrets` at task startup). Without this, Terraform
  # has no reason to finish aws_secretsmanager_secret_version.this before
  # anything depending on secret_arns proceeds.
  depends_on = [aws_secretsmanager_secret_version.this]
}

output "secret_arns" {
  description = "Map of secret name => ARN, consumed by the fargate module (container `secrets`) and the iam module (execution role read policy). NOTE: these secrets have no value until set manually outside Terraform — ECS will fail to start the task until every one of them has a value."
  value       = { for k, s in aws_secretsmanager_secret.this : k => s.arn }
}

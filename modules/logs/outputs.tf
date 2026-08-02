output "log_group_name" {
  description = "Name of the log group, referenced by the fargate module's container definition."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the log group."
  value       = aws_cloudwatch_log_group.this.arn
}

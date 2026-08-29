output "lambda_function_name" {
  description = "Name of the DNS-sync Lambda — check its CloudWatch Logs to confirm it's firing and updating Route 53 correctly."
  value       = aws_lambda_function.dns_sync.function_name
}

output "event_rule_name" {
  description = "Name of the EventBridge rule triggering the Lambda on ECS task state changes."
  value       = aws_cloudwatch_event_rule.task_running.name
}

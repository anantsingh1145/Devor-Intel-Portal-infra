output "dns_name" {
  description = "ALB's AWS-generated DNS name. Not a working app URL (the listener rule rejects any Host header other than var.domain_name) - only needed as the CNAME target when pointing var.domain_name at this ALB."
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "Target group ARN the ECS service registers tasks with."
  value       = aws_lb_target_group.app.arn
}

output "https_listener_arn" {
  description = "HTTPS listener ARN, used to sequence the ECS service after the listener/rule exist."
  value       = aws_lb_listener.https.arn
}

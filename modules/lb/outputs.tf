output "alb_arn" {
  description = "ARN of the ALB."
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (what you'd CNAME/alias a custom domain to)."
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID of the ALB, needed for alias records."
  value       = module.alb.zone_id
}

output "target_group_arn" {
  description = "ARN of the Chronicle target group, consumed by the fargate module's ECS service."
  value       = module.alb.target_groups["chronicle"].arn

  # The target group ARN exists as soon as it's created, but the ECS service
  # that registers against it also needs the ALB's listener(s) to exist —
  # a known ECS+ALB race if the service is created before any listener
  # forwards to this target group. depends_on the whole module so both the
  # target group AND its listener(s) are guaranteed done first.
  depends_on = [module.alb]
}

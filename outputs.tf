output "alb_dns_name" {
  description = "ALB's public DNS name. If domain_name/route53_zone_id weren't set, this is how you reach Chronicle."
  value       = module.lb.alb_dns_name
}

output "app_url" {
  description = "Best-guess URL for reaching the app: the custom domain if configured, otherwise the ALB DNS name over HTTP."
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${module.lb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "Push images here: docker push <this>:<tag>."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name."
  value       = module.fargate.service_name
}

output "efs_file_system_id" {
  description = "EFS filesystem ID holding chronicle.db."
  value       = module.efs.file_system_id
}

output "log_group_name" {
  description = "CloudWatch Log Group the container logs to."
  value       = module.logs.log_group_name
}

output "secret_arns" {
  description = "Map of secret name => Secrets Manager ARN created for this environment."
  value       = module.secrets.secret_arns
}

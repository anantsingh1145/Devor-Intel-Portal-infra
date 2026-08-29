output "app_url" {
  description = "Reachable here (HTTP only — no ALB/ACM in this architecture) a few seconds after the task starts, once modules/dns_sync updates the record. Null if no custom domain is configured — with no ALB and no static IP, there's no fixed address in that case; find the running task's current public IP via `aws ecs describe-tasks` / the ECS console instead."
  value       = var.domain_name != "" ? "http://${var.domain_name}" : null
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

output "app_url" {
  description = "The only supported way to reach the app. Direct access via the ALB's own DNS name, the ECS task's IP, or plain HTTP is rejected/redirected."
  value       = "https://${var.domain_name}"
}

output "alb_dns_name" {
  description = "ALB's AWS-generated DNS name. Not a working app URL on its own (the listener rule rejects any Host header other than var.domain_name) — this is the CNAME target to use when pointing var.domain_name at the ALB at your DNS provider."
  value       = module.alb.dns_name
}

output "acm_certificate_validation_record" {
  description = "DNS record to create manually at your domain's DNS provider to validate the ACM certificate: { name, type, value }. terraform apply waits here until ACM sees it — add it, wait for propagation, then re-run apply."
  value       = module.acm.validation_record
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

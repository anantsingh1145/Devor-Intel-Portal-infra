output "service_id" {
  description = "ECS service ID."
  value       = module.fargate_service.id
}

output "service_name" {
  description = "ECS service name."
  value       = module.fargate_service.name
}

output "task_definition_arn" {
  description = "ARN of the registered task definition."
  value       = module.fargate_service.task_definition_arn
}

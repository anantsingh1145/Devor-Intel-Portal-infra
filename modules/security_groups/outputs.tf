output "ecs_task_security_group_id" {
  description = "Security group ID for the ECS Fargate tasks."
  value       = module.ecs_task_sg.security_group_id
}

output "efs_security_group_id" {
  description = "Security group ID for the EFS filesystem."
  value       = module.efs_sg.security_group_id
}

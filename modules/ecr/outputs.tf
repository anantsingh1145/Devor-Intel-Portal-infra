output "repository_url" {
  description = "URL used to `docker push`/`docker pull` and in the ECS task definition image field."
  value       = module.ecr.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = module.ecr.repository_arn
}

output "repository_name" {
  description = "Name of the ECR repository."
  value       = module.ecr.repository_name
}

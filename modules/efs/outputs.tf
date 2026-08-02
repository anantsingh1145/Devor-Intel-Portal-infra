output "file_system_id" {
  description = "EFS filesystem ID."
  value       = module.efs.id
}

output "file_system_arn" {
  description = "EFS filesystem ARN."
  value       = module.efs.arn
}

output "access_point_id" {
  description = "Access point ID the ECS task volume mounts."
  value       = module.efs.access_points["chronicle"].id

  # The filesystem/access point resources exist as soon as created, but a
  # Fargate task actually mounting this needs the mount targets (in each
  # subnet) to be available too. depends_on the whole module so consumers
  # wait for mount targets, not just the filesystem/access point attributes.
  depends_on = [module.efs]
}

output "access_point_arn" {
  description = "Access point ARN, used in the task role's IAM policy."
  value       = module.efs.access_points["chronicle"].arn
}

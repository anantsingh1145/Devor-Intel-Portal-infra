variable "name_prefix" {
  description = "Prefix used to name the IAM roles."
  type        = string
}

variable "secret_arns" {
  description = "Secrets Manager ARNs the task's container definition resolves at startup (read via the execution role, per ECS's design)."
  type        = list(string)
  default     = []
}

variable "efs_file_system_arn" {
  description = "ARN of the EFS filesystem the task role is allowed to mount."
  type        = string
}

variable "efs_access_point_arn" {
  description = "ARN of the EFS access point the task role is scoped to (via the elasticfilesystem:AccessPointArn condition)."
  type        = string
}

variable "tags" {
  description = "Tags applied to the IAM roles."
  type        = map(string)
  default     = {}
}

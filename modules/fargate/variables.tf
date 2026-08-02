variable "name" {
  description = "Name of the ECS service and its single container/task definition."
  type        = string
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster (from modules/ecs) to run the service on."
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN (from modules/iam)."
  type        = string
}

variable "task_role_arn" {
  description = "ECS task role ARN (from modules/iam)."
  type        = string
}

variable "cpu" {
  description = "Task-level vCPU units (Fargate: 256/512/1024/2048/...)."
  type        = number
  default     = 512
}

variable "memory" {
  description = "Task-level memory in MiB, must be a valid Fargate cpu/memory pairing."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "image" {
  description = "Full container image URI including tag, e.g. \"<account>.dkr.ecr.<region>.amazonaws.com/chronicle-app:latest\"."
  type        = string
}

variable "container_port" {
  description = "Port the Chronicle (Streamlit) container listens on."
  type        = number
  default     = 8501
}

variable "environment" {
  description = "Plain (non-secret) environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Map of container env var name => Secrets Manager ARN (from modules/secrets), injected at task startup."
  type        = map(string)
  default     = {}
}

variable "log_group_name" {
  description = "CloudWatch Log Group name (from modules/logs) the container logs to."
  type        = string
}

variable "aws_region" {
  description = "Region used for the awslogs log driver configuration."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the task ENIs are placed in."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the task ENIs (from modules/security_groups)."
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group ARN (from modules/lb) the service registers tasks with."
  type        = string
}

variable "efs_file_system_id" {
  description = "EFS filesystem ID (from modules/efs) mounted into the container."
  type        = string
}

variable "efs_access_point_id" {
  description = "EFS access point ID (from modules/efs) used for the volume mount."
  type        = string
}

variable "container_mount_path" {
  description = "Path inside the container where the EFS volume (holding chronicle.db) is mounted."
  type        = string
  default     = "/data"
}

variable "fargate_weight" {
  description = "Relative weight for the FARGATE capacity provider in this service's placement strategy."
  type        = number
  default     = 100
}

variable "fargate_base" {
  description = "Minimum tasks placed on FARGATE before FARGATE_SPOT is used."
  type        = number
  default     = 1
}

variable "fargate_spot_weight" {
  description = "Relative weight for FARGATE_SPOT. Set > 0 in cost-sensitive, non-prod environments."
  type        = number
  default     = 0
}

variable "enable_autoscaling" {
  description = "Enable target-tracking autoscaling on CPU utilization."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks."
  type        = number
  default     = 2
}

variable "autoscaling_cpu_target" {
  description = "Target average CPU utilization percentage for autoscaling."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags applied to the service and task definition."
  type        = map(string)
  default     = {}
}

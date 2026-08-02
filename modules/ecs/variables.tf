variable "name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "container_insights_enabled" {
  description = "Enable CloudWatch Container Insights for the cluster."
  type        = bool
  default     = false
}

variable "fargate_weight" {
  description = "Relative weight for the FARGATE capacity provider in the default strategy."
  type        = number
  default     = 100
}

variable "fargate_base" {
  description = "Minimum number of tasks that must run on FARGATE before FARGATE_SPOT is used."
  type        = number
  default     = 1
}

variable "fargate_spot_weight" {
  description = "Relative weight for the FARGATE_SPOT capacity provider in the default strategy. Set > 0 in cost-sensitive, non-prod environments."
  type        = number
  default     = 0
}

variable "tags" {
  description = "Tags applied to the cluster."
  type        = map(string)
  default     = {}
}

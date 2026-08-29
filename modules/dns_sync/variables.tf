variable "name_prefix" {
  description = "Prefix used to name the Lambda, its IAM role, and the EventBridge rule."
  type        = string
}

variable "ecs_cluster_arn" {
  description = "ECS cluster ARN (from modules/ecs) to filter EventBridge task-state-change events to."
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID containing the record to keep updated."
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain name (the A record) to keep pointed at the task's current public IP."
  type        = string
}

variable "record_ttl" {
  description = "TTL (seconds) set on the A record each time it's updated. Kept low so DNS resolvers pick up IP changes quickly."
  type        = number
  default     = 60
}

variable "tags" {
  description = "Tags applied to the Lambda, its role, and the EventBridge rule."
  type        = map(string)
  default     = {}
}

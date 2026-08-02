variable "name" {
  description = "Name of the ALB."
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the ALB and target group in."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets the ALB is deployed into (needs at least 2 AZs)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the ALB."
  type        = string
}

variable "app_port" {
  description = "Port the Chronicle container listens on; the target group forwards to this port."
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the target group health check requests."
  type        = string
  default     = "/"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener. Leave null to serve plain HTTP only (no HTTPS listener, no redirect)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the ALB and target group."
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix used to name the ALB and its target group."
  type        = string
}

variable "vpc_id" {
  description = "VPC the ALB and target group belong to."
  type        = string
}

variable "subnet_ids" {
  description = "Public subnets the ALB is placed in (at least 2 AZs)."
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the ALB (from modules/security_groups)."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN (from modules/acm) for the HTTPS listener."
  type        = string
}

variable "domain_name" {
  description = "Fully qualified domain the app is served on, e.g. \"www.devor.net\". Requests for any other Host header are rejected."
  type        = string
}

variable "target_port" {
  description = "Port the ECS task listens on."
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the target group health check requests."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags applied to the ALB and target group."
  type        = map(string)
  default     = {}
}

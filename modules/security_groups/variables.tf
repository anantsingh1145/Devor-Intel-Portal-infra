variable "name_prefix" {
  description = "Prefix used to name each security group."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups belong to."
  type        = string
}

variable "app_port" {
  description = "Port the Chronicle container listens on (the ALB target group forwards to this port)."
  type        = number
}

variable "tags" {
  description = "Tags applied to all security groups."
  type        = map(string)
  default     = {}
}

variable "name" {
  description = "CloudWatch Log Group name, e.g. \"/ecs/chronicle-dev\"."
  type        = string
}

variable "retention_in_days" {
  description = "How long to retain logs before they expire."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags applied to the log group."
  type        = map(string)
  default     = {}
}

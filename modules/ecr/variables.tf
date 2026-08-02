variable "repository_name" {
  description = "Name of the ECR repository (e.g. chronicle-app)."
  type        = string
}

variable "image_retention_count" {
  description = "Maximum number of tagged images to retain before older ones expire."
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Allow deleting the repository even if it still contains images (useful for dev/preprod)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the repository."
  type        = map(string)
  default     = {}
}

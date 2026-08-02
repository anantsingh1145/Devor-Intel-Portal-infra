variable "domain_name" {
  description = "Domain name to issue a certificate for. Leave empty to skip ACM/HTTPS entirely (ALB serves HTTP only)."
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "Route 53 hosted zone ID used for DNS validation. Required when var.domain_name is set."
  type        = string
  default     = ""
}

variable "subject_alternative_names" {
  description = "Additional domain names to cover with the same certificate."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to the certificate."
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Fully qualified domain the certificate is issued for, e.g. \"www.devor.net\"."
  type        = string
}

variable "tags" {
  description = "Tags applied to the certificate."
  type        = map(string)
  default     = {}
}

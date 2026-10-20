variable "domain_name" {
  description = "Primary domain the certificate is issued for, e.g. \"www.devor.net\"."
  type        = string
}

variable "root_domain" {
  description = "Apex domain added as a SAN, e.g. \"devor.net\"."
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID where the DNS validation records are created."
  type        = string
}

variable "tags" {
  description = "Tags applied to the certificate."
  type        = map(string)
  default     = {}
}

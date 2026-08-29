variable "zone_id" {
  description = "Route 53 hosted zone ID to create the record in. Leave empty (with domain_name) to skip DNS entirely."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Fully qualified domain name to point at the ECS task's public IP, e.g. \"chronicle.example.com\". Leave empty to skip DNS entirely."
  type        = string
  default     = ""
}

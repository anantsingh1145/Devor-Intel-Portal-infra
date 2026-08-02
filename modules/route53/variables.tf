variable "zone_id" {
  description = "Route 53 hosted zone ID to create the record in. Leave empty (with domain_name) to skip DNS entirely."
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Fully qualified domain name to point at the ALB, e.g. \"chronicle.example.com\". Leave empty to skip DNS entirely."
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "ALB DNS name (from modules/lb) the alias record points to."
  type        = string
  default     = ""
}

variable "alb_zone_id" {
  description = "ALB's own Route 53 hosted zone ID (from modules/lb), required for an alias record."
  type        = string
  default     = ""
}

variable "name" {
  description = "Name of the AWS Budget."
  type        = string
}

variable "limit_amount" {
  description = "Monthly spend limit, as a string (e.g. \"20\")."
  type        = string
}

variable "limit_unit" {
  description = "Currency for limit_amount."
  type        = string
  default     = "USD"
}

variable "notification_emails" {
  description = "Email addresses to notify on budget alerts. AWS requires at least one subscriber per notification."
  type        = list(string)
}

variable "alert_thresholds_percent" {
  description = "Percent-of-budget thresholds that trigger an ACTUAL-spend email alert (in addition to a fixed FORECASTED-spend alert at 100%)."
  type        = list(number)
  default     = [80, 100]
}

variable "tags" {
  description = "Tags applied to the budget."
  type        = map(string)
  default     = {}
}

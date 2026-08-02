variable "name_prefix" {
  description = "Prefix used to namespace secret names, e.g. \"chronicle/dev\"."
  type        = string
}

variable "secret_names" {
  description = "Secret names to create as empty containers (e.g. [\"SERPER_API_KEY\", \"SMTP_PASSWORD\"]). No values pass through this module — set them manually after apply. Add a name here to create a new secret — no module code changes needed."
  type        = list(string)
}

variable "recovery_window_in_days" {
  description = "Days AWS retains a deleted secret before permanent removal (0 disables recovery, useful for dev)."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags applied to every secret."
  type        = map(string)
  default     = {}
}

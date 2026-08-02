variable "name_prefix" {
  description = "Prefix used to namespace secret names, e.g. \"chronicle/dev\"."
  type        = string
}

variable "secrets" {
  description = "Map of secret name => sensitive value (e.g. { anthropic_api_key = \"...\", smtp_password = \"...\" }). Add a new key here to create a new secret — no module code changes needed."
  type        = map(string)
  sensitive   = true
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

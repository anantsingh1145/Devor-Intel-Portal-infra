variable "name" {
  description = "Name of the EFS filesystem."
  type        = string
}

variable "subnet_ids" {
  description = "Subnets to place one mount target in each."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to the mount targets (from modules/security_groups)."
  type        = list(string)
}

variable "access_point_path" {
  description = "Root directory the access point exposes; this is where chronicle.db lives inside the container's mounted volume."
  type        = string
  default     = "/chronicle-data"
}

variable "posix_uid" {
  description = "POSIX UID the access point enforces (should match the container's runtime user)."
  type        = number
  default     = 1000
}

variable "posix_gid" {
  description = "POSIX GID the access point enforces (should match the container's runtime group)."
  type        = number
  default     = 1000
}

variable "tags" {
  description = "Tags applied to the filesystem."
  type        = map(string)
  default     = {}
}

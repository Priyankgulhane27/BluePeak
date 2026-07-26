variable "name_prefix" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string }
variable "database_name" {
  type    = string
  default = "bluepeak"
}
variable "master_username" {
  type    = string
  default = "bluepeak_admin"
}
variable "engine_version" {
  type    = string
  default = "8.0.mysql_aurora.3.07.1"
}
variable "min_acu" {
  type        = number
  default     = 0.5
  description = "Minimum Aurora Capacity Units - scales down automatically off-hours"
}
variable "max_acu" {
  type        = number
  default     = 4
  description = "Maximum Aurora Capacity Units - scales up automatically under load"
}
variable "instance_count" {
  type        = number
  default     = 2
  description = "2 = Multi-AZ HA with automated failover"
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "apply_immediately" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

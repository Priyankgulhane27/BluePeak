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
  type        = string
  default     = "16.14"
  description = "RDS PostgreSQL version. Check availability with: aws rds describe-db-engine-versions --engine postgres --region <region>"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "AWS Free Tier covers 750 hrs/month of db.t3.micro or db.t4g.micro Single-AZ PostgreSQL"
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "AWS Free Tier covers 20 GB of gp2 storage"
}

variable "max_allocated_storage" {
  type        = number
  default     = 100
  description = "Enables RDS storage autoscaling above allocated_storage as data grows. Only billed if actually used."
}

variable "multi_az" {
  type        = bool
  default     = false
  description = "AWS Free Tier does not cover Multi-AZ. Set true once off the Free Plan for real HA/automated failover."
}

variable "backup_retention_days" {
  type        = number
  default     = 1
  description = "AWS Free Plan accounts cap this at 1 day. Raise to 7+ once off the free plan."
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "performance_insights_enabled" {
  type        = bool
  default     = false
  description = "Left off by default - a paid add-on feature, disabled for Free Plan safety. Enable once off Free Plan."
}

variable "monitoring_interval" {
  type        = number
  default     = 0
  description = "RDS Enhanced Monitoring interval in seconds (0 = disabled). Left off by default for Free Plan safety."
}

variable "tags" {
  type    = map(string)
  default = {}
}

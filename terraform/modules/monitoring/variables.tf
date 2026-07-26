variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "alert_email" {
  type    = string
  default = null
}
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "rds_cluster_id" { type = string }
variable "max_db_connections_threshold" {
  type    = number
  default = 200
}
variable "tags" {
  type    = map(string)
  default = {}
}

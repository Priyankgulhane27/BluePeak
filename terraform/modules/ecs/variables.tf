variable "name_prefix" { type = string }
variable "aws_region" { type = string }
variable "app_subnet_ids" { type = list(string) }
variable "app_sg_id" { type = string }
variable "target_group_arn" { type = string }
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "db_secret_arn" { type = string }

variable "container_image" {
  type        = string
  description = "Full ECR image URI, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/bluepeak-counter:latest"
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 2
  description = "Minimum tasks - keep >=2 across AZs for HA"
}

variable "max_capacity" {
  type    = number
  default = 10
}

variable "cpu_target_value" {
  type    = number
  default = 60
}

variable "requests_per_target_value" {
  type    = number
  default = 500
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "true saves ~$65/mo/extra-NAT for a dev environment; set false in prod for HA egress"
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "container_image" {
  type        = string
  description = "ECR image URI produced by scripts/build_and_push.sh"
}

variable "certificate_arn" {
  type        = string
  default     = null
  description = "ACM cert ARN for HTTPS. Leave null to run plain HTTP (fine for this assessment)."
}

variable "database_name" {
  type    = string
  default = "bluepeak"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "AWS Free Tier covers 750 hrs/month of db.t3.micro or db.t4g.micro Single-AZ"
}

variable "db_multi_az" {
  type        = bool
  default     = false
  description = "AWS Free Tier does not cover Multi-AZ. Set true once off the Free Plan."
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "ecs_min_capacity" {
  type    = number
  default = 2
}

variable "ecs_max_capacity" {
  type    = number
  default = 10
}

variable "alert_email" {
  type        = string
  default     = null
  description = "Email to receive SNS alarm notifications. Leave null to skip subscription."
}

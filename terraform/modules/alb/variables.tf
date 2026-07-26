variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_port" {
  type    = number
  default = 3000
}
variable "certificate_arn" {
  type        = string
  default     = null
  description = "ACM certificate ARN. If null, ALB serves plain HTTP (fine for the assessment demo; use a real domain + ACM cert for production)."
}
variable "access_logs_bucket" {
  type    = string
  default = null
}
variable "enable_deletion_protection" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

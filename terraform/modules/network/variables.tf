variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3 for HA without excessive cost."
  }
}

variable "single_nat_gateway" {
  type        = bool
  default     = false
  description = "true = 1 NAT GW total (cheaper, single point of failure for outbound traffic). false = 1 per AZ (HA, higher cost). Recommended false for production."
}

variable "flow_log_retention_days" {
  type    = number
  default = 90
}

variable "tags" {
  type    = map(string)
  default = {}
}

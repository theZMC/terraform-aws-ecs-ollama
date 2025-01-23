variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones. If not provided, the first two available AZs will be used."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.availability_zones) == 0 || length(var.availability_zones) >= 2
    error_message = "If specifying availability zones, you must provide at least two zones for high availability."
  }
}

variable "basic_auth_username" {
  description = "Username for basic auth to use with the ALB"
  type        = string
}

variable "basic_auth_password" {
  description = "Password for basic auth to use with the ALB"
  type        = string

  validation {
    condition     = length(var.basic_auth_password) >= 12
    error_message = "Password must be at least 12 characters long."
  }
}

variable "gpu_brand" {
  description = "GPU brand to use for EC2 instances"
  type        = string
  default     = "nvidia"

  validation {
    condition     = var.gpu_brand == "nvidia" || var.gpu_brand == "amd"
    error_message = "GPU brand must be either 'nvidia' or 'amd'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "alb_inbound_cidrs" {
  description = "List of CIDR blocks to allow inbound traffic to the ALB"
  type        = list(string)
  default     = []
}

variable "route53_zone_name" {
  description = "Route53 zone name to use for the application"
  type        = string
}

variable "subdomain" {
  description = "Subdomain to use for the application; will be appended to the Route53 zone name"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to use for the load balancer"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.public_subnet_ids) > 1
    error_message = "You must provide at least two public subnet IDs"
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs to use for the application; the first one will be used for the EC2 instance"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.private_subnet_ids) > 0
    error_message = "You must provide at least one private subnet ID."
  }
}

variable "use_spot" {
  description = "Whether to use spot instances for the EC2 instance"
  type        = bool
  default     = false
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

variable "ollama_model" {
  description = "Ollama model to use for the application"
  type        = string
  default     = "llama3:8b"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

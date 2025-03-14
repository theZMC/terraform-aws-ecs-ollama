# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Get latest Bottlerocket AMI
data "aws_ssm_parameter" "ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended/image_id"
}

locals {
  number_of_azs = 2
  # Use provided AZs or default to first two available
  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, local.number_of_azs)

  # Calculate subnet CIDRs from VPC CIDR
  # Creates 4 subnets (2 public, 2 private) with equal size
  # Each subnet will be 2 bits smaller than the VPC CIDR
  private_subnet_cidrs = [
    for index in range(local.number_of_azs) :
    cidrsubnet(var.vpc_cidr, 2, index)
  ]

  public_subnet_cidrs = [
    for index in range(local.number_of_azs) :
    cidrsubnet(var.vpc_cidr, 2, index + local.number_of_azs)
  ]
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

# Security Groups
module "ecs_service_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5"

  name        = "${var.project_name}-ecs-service-sg"
  description = "Security group for ECS services"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = var.tags
}

# ECS Cluster
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5"

  cluster_name = "${var.project_name}-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${var.project_name}"
      }
    }
  }

  autoscaling_capacity_providers = {
    asg-capacity-provider = {
      auto_scaling_group_arn         = module.asg.autoscaling_group_arn
      managed_termination_protection = "ENABLED"

      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 80
      }

      default_capacity_provider_strategy = {
        weight = 40
      }
    }
  }

  tags = var.tags
}

# Auto Scaling Group
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7"

  name = "${var.project_name}-asg"

  vpc_zone_identifier = module.vpc.private_subnets
  security_groups     = [module.ecs_service_sg.security_group_id]

  # IAM role with SSM and ECS permissions
  create_iam_instance_profile = true
  iam_role_name               = "${var.project_name}-ecs-instance"
  iam_role_description        = "ECS instance role with SSM access"
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Launch template
  create_launch_template = true
  enable_monitoring      = true
  image_id               = data.aws_ssm_parameter.ami_id.value
  user_data = base64encode(templatefile(
    "${path.module}/templates/al2-user-data.sh.tftpl",
    {
      cluster_name = module.ecs.cluster_name,
    }
  ))

  update_default_version     = true
  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 10
      on_demand_allocation_strategy            = "lowest-price"
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }
  instance_refresh = {
    strategy = "Rolling"
  }

  instance_requirements = {
    accelerator_manufacturers = [var.gpu_brand]
    accelerator_total_memory_mib = {
      min = 8192
      max = 16384
    }
    max_spot_price_as_percentage_of_optimal_on_demand_price = 80
    memory_mib = {
      min = 4096
      max = 16384
    }
    vcpu_count = {
      min = 2
      max = 8
    }
  }

  min_size = 1
  max_size = 3

  metadata_options = {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  protect_from_scale_in = true
  tags                  = var.tags
}

# ALB Security Group - Only allow traffic from CloudFront
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5"

  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = []
  ingress_with_prefix_list_ids = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      description     = "HTTP from CloudFront"
      prefix_list_ids = data.aws_ec2_managed_prefix_list.cloudfront.id
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = "${var.project_name}-alb"

  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [module.alb_sg.security_group_id]

  listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = "${var.project_name}-webui"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      target_id        = module.ecs.cluster_id


      health_check = {
        path    = "/"
        port    = 8080
        matcher = "200-399"
      }
    }
  ]

  tags = var.tags
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "webui" {
  enabled = true

  origin {
    domain_name = module.alb.dns_name
    origin_id   = "alb"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "alb"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# CloudFront Function for Basic Auth
resource "aws_cloudfront_function" "basic_auth" {
  name    = "${var.project_name}-basic-auth"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = <<-JavaScript
    function handler(event) {
        var request = event.request;
        var headers = request.headers;

        // Get auth credentials
        var authString = "Basic " + btoa("${var.basic_auth_username}:${var.basic_auth_password}");

        // Challenge if no auth header or incorrect credentials
        if (!headers.authorization || headers.authorization.value !== authString) {
            return {
                statusCode: 401,
                statusDescription: "Unauthorized",
                headers: {
                    "www-authenticate": {
                        value: "Basic"
                    }
                }
            };
        }

        return request;
    }
  JavaScript
}

# EFS File System for Ollama data
resource "aws_efs_file_system" "ollama" {
  creation_token = "${var.project_name}-ollama-data"

  tags = var.tags
}

resource "aws_efs_mount_target" "ollama" {
  count           = length(module.vpc.private_subnets)
  file_system_id  = aws_efs_file_system.ollama.id
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "NFS from ECS tasks"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.ecs_service_sg.security_group_id]
  }

  tags = var.tags
}

locals {
  ollama_image = var.gpu_brand == "nvidia" ? "ollama/ollama:latest" : "ollama/ollama:rocm"
}

module "ollama_ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5"

  name = "ollama"

  cluster_arn = module.ecs.cluster_id

  cpu    = 1024
  memory = 4096

  subnet_ids  = module.vpc.private_subnets
  launch_type = "EC2"

  create_iam_role    = true
  security_group_ids = [module.ecs_service_sg.security_group_id]

  volume = {
    ollama-data = {
      efs_volume_configuration = {
        file_system_id = aws_efs_file_system.ollama.id
        root_directory = "/"
      }
    }
  }

  requires_compatibilities = [
    "EC2"
  ]

  container_definitions = {
    webui = {
      cpu                      = 256
      memory                   = 1024
      essential                = true
      image                    = "ghcr.io/open-webui/open-webui:main"
      readonly_root_filesystem = false
      port_mappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "OLLAMA_API_BASE_URL"
          value = "http://localhost:11434"
        }
      ]
    },
    ollama = {
      cpu       = 768
      memory    = 3072
      essential = true
      image     = local.ollama_image
      port_mappings = [
        {
          containerPort = 11434
          hostPort      = 11434
          protocol      = "tcp"
        }
      ]
      mount_points = [
        {
          sourceVolume  = "ollama-data"
          containerPath = "/root/.ollama"
          readOnly      = false
        }
      ]
      resource_requirements = [{
        type  = "GPU"
        value = "1"
      }]
    }
  }
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.subdomain
  type    = "CNAME"
  ttl     = 300
  records = [module.alb.dns_name]
}

module "tls" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4"

  domain_name         = "${var.subdomain}.${data.aws_route53_zone.this.name}"
  zone_id             = data.aws_route53_zone.this.zone_id
  wait_for_validation = true
  validation_method   = "DNS"
}

module "ecs_service_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5"

  name        = "${var.project_name}-ecs-service-sg"
  description = "Security group for ECS services"
  vpc_id      = local.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
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

  tags = var.tags
}

resource "aws_iam_role" "instance" {
  name               = "${var.project_name}-ecs-instance"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_instance_role" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.instance.name
}

resource "aws_security_group" "spot" {
  name        = "${var.project_name}-ecs-spot-sg"
  description = "Security group for ECS Spot instances"
  vpc_id      = local.vpc_id

  egress = [
    {
      description      = "Allow all outbound traffic"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      security_groups  = []
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      self             = false
    }
  ]
}

resource "aws_launch_template" "this" {
  name_prefix = "${var.project_name}-launch-template"
  image_id    = data.aws_ssm_parameter.ami_id.value
  user_data = base64encode(templatefile(
    "${path.module}/templates/al2-user-data.sh.tftpl",
    {
      cluster_name = module.ecs.cluster_name,
    }
  ))

  placement {
    availability_zone = local.ec2_az
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance.arn
  }

  network_interfaces {
    security_groups = [aws_security_group.spot.id]
    subnet_id       = var.private_subnet_ids[0]
  }

  instance_requirements {
    accelerator_manufacturers = [var.gpu_brand]
    accelerator_count {
      min = 1
    }
    accelerator_total_memory_mib {
      min = local.model_size_mb
    }
    memory_mib {
      min = 4096
    }
    vcpu_count {
      min = 2
    }
  }

  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-ecs-spot-instance"
      }
    )
  }
}

resource "aws_ec2_fleet" "spot" {
  type = "maintain"

  target_capacity_specification {
    default_target_capacity_type = var.use_spot ? "spot" : "on-demand"
    total_target_capacity        = 1
  }

  excess_capacity_termination_policy = "termination"

  dynamic "spot_options" {
    for_each = var.use_spot ? [1] : []
    content {
      allocation_strategy         = "lowest-price"
      instance_pools_to_use_count = 1
      maintenance_strategies {
        capacity_rebalance {
          replacement_strategy = "launch-before-terminate"
          termination_delay    = 120
        }
      }
    }
  }

  launch_template_config {
    launch_template_specification {
      launch_template_id = aws_launch_template.this.id
      version            = aws_launch_template.this.latest_version
    }
    override {
      availability_zone = local.ec2_az
    }
  }

  terminate_instances = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ecs-spot-fleet"
    }
  )
}

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5"

  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = concat(
    [
      for cidr in var.alb_inbound_cidrs :
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = cidr
      }
    ],
    [
      for cidr in var.alb_inbound_cidrs :
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = cidr
      }
    ]
  )

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

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = var.project_name

  load_balancer_type         = "application"
  vpc_id                     = local.vpc_id
  subnets                    = var.public_subnet_ids
  security_groups            = [module.alb_sg.security_group_id]
  internal                   = false
  enable_deletion_protection = false

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = module.tls.acm_certificate_arn
      fixed_response = {
        content_type = "text/plain"
        message_body = "404: Not Found"
        status_code  = "404"
      }
      rules = {
        ollama-webui = {
          actions = [
            {
              type             = "forward"
              target_group_key = "ollama-webui"
            }
          ],
          conditions = [{
            path_pattern = {
              values = ["/*"]
            }
          }]
        }
      }
    }
  }

  target_groups = {
    ollama-webui = {
      name_prefix      = "webui"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = "ip"
      health_check = {
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
      }
      create_attachment = false
    }
  }

  tags = var.tags
}

module "ollama_ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5"

  name = "ollama"

  cluster_arn = module.ecs.cluster_id

  cpu    = 1024
  memory = 4096

  # A little downtime never hurt nobody
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  enable_execute_command = var.allow_ecs_exec

  subnet_ids  = var.private_subnet_ids
  launch_type = "EC2"

  create_iam_role    = true
  security_group_ids = [module.ecs_service_sg.security_group_id]

  requires_compatibilities = [
    "EC2"
  ]

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["ollama-webui"].arn
      container_name   = "webui"
      container_port   = 8080
    }
  }

  container_definitions = {
    webui = {
      cpu                      = 128
      memory                   = 768
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
          name  = "OLLAMA_BASE_URL"
          value = "http://localhost:11434"
        },
        {
          name  = "WEBUI_URL"
          value = "https://${var.subdomain}.${data.aws_route53_zone.this.name}"
        },
        {
          name  = "ENABLE_OPENAI_API"
          value = "false"
        }
      ]
    },
    ollama = {
      cpu                      = 768
      memory                   = 3072
      essential                = true
      image                    = local.ollama_image
      readonly_root_filesystem = false
      port_mappings = [
        {
          containerPort = 11434
          hostPort      = 11434
          protocol      = "tcp"
        }
      ]
      resource_requirements = [{
        type  = "GPU"
        value = "1"
      }]
      # I haven't been able to get this to work yet
      # health_check = {
      #   command     = ["cmd-shell", "ollama list || exit 1"]
      #   interval    = 30
      #   timeout     = 5
      #   retries     = 3
      #   startPeriod = 60
      # }
    }
    # # https://github.com/ollama/ollama/issues/2431
    # download-model = {
    #   cpu       = 128
    #   memory    = 256
    #   essential = false
    #   image     = "alpine/curl:8.12.1"
    #   cmd = [
    #     "http://localhost:11434/api/chat -d '{\"model\":\"${local.model_name}:${local.model_version}\"}'"
    #   ]
    #   dependencies = [{
    #     containerName = "ollama"
    #     condition     = "HEALTHY"
    #   }]
    # }
  }
  security_group_rules = {
    allow_alb_ingress = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
    },
    allow_internet_egress = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

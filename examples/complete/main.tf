################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = local.tags
}


################################################################################
# ECS Ollama Module
################################################################################

module "ecs_ollama" {
  source       = "../.."
  project_name = local.name

  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  route53_zone_name = var.route53_zone_name
  subdomain         = "ecs-ollama"
  alb_inbound_cidrs = [
    "${data.http.my_ip.response_body}/32",
  ]

  # https://www.ollama.com/library
  ollama_model = "qwen3:4b"
  gpu_brand    = "nvidia"

  tags = local.tags
}

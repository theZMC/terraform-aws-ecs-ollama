provider "aws" {
  region = local.region
}

locals {
  region = "us-east-1"
  name   = "ecs-ollama-ex-${basename(path.cwd)}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/thezmc/terraform-aws-ecs-ollama"
  }
}

data "http" "my_ip" {
  url = "http://ifconfig.me"
  request_headers = {
    "User-Agent" = "curl"
  }
}

################################################################################
# ecs ollama Module
################################################################################

module "ecs_ollama" {
  source       = "../.."
  project_name = local.name
  vpc_cidr     = "172.16.100.0/24"

  basic_auth_username = "admin"
  basic_auth_password = "thisisaverysecurepassword"
  route53_zone_name   = var.route53_zone_name
  subdomain           = "ecs-ollama"
  alb_inbound_cidrs = [
    "${data.http.my_ip.response_body}/32",
  ]

  tags = local.tags
}

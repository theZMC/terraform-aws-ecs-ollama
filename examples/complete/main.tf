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

################################################################################
# ecs ollama Module
################################################################################

module "ecs_ollama" {
  source       = "../.."
  project_name = local.name
  vpc_cidr     = "172.16.100.0/24"

  basic_auth_username = "admin"
  basic_auth_password = "thisisaverysecurepassword"

  tags = local.tags
}

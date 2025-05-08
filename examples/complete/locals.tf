locals {
  region   = "us-east-1"
  name     = "ecs-ollama-ex-${basename(path.cwd)}"
  vpc_cidr = "192.168.128.0/26"

  number_of_azs = 2

  # Use provided AZs or default to first two available
  azs = slice(data.aws_availability_zones.available.names, 0, local.number_of_azs)

  # Calculate subnet CIDRs from VPC CIDR
  # Creates 4 subnets (2 public, 2 private) with equal size
  # Each subnet will be 2 bits smaller than the VPC CIDR
  private_subnet_cidrs = [
    for index in range(local.number_of_azs) :
    cidrsubnet(local.vpc_cidr, 2, index)
  ]

  public_subnet_cidrs = [
    for index in range(local.number_of_azs) :
    cidrsubnet(local.vpc_cidr, 2, index + local.number_of_azs)
  ]

  tags = {
    Name       = local.name
    Example    = basename(path.cwd)
    Repository = "https://github.com/thezmc/terraform-aws-ecs-ollama"
  }
}

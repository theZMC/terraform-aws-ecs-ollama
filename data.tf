data "aws_ssm_parameter" "ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended/image_id"
}

data "http" "ollama_model_manifest" {
  url = format(local.manifest_url_format, local.model_name, local.model_version)
}

data "aws_route53_zone" "this" {
  name = var.route53_zone_name
}

data "aws_subnet" "private" {
  id = var.private_subnet_ids[0]
}

# AWS ECS Ollama Terraform module

Terraform module which creates an Ollama instance with a paired web interface (using Open-WebUI) on ECS.

## Usage

See [`examples`](https://github.com/thezmc/terraform-aws-ecs-ollama/tree/main/examples) directory for working examples to reference:

```hcl
module "ecs_ollama" {
  source       = "../.."
  project_name = "ecs-ollama"
  vpc_cidr     = "172.16.100.0/24"

  basic_auth_username = "admin"
  basic_auth_password = "thisisaverysecurepassword"

  tags = local.tags
}
```

## Examples

Examples codified under the [`examples`](https://github.com/thezmc/terraform-aws-ecs-ollama/tree/main/examples) are intended to give users references for how to use the module(s) as well as testing/validating changes to the source code of the module. If contributing to the project, please be sure to make any appropriate updates to the relevant examples to allow maintainers to test your changes and to keep the examples up to date for users. Thank you!

- [Complete](https://github.com/thezmc/terraform-aws-ecs-ollama/tree/main/examples/complete)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5 |
| <a name="requirement_http"></a> [http](#requirement\_http) | ~> 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5 |
| <a name="provider_http"></a> [http](#provider\_http) | ~> 3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_alb_sg"></a> [alb\_sg](#module\_alb\_sg) | terraform-aws-modules/security-group/aws | ~> 5 |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | terraform-aws-modules/ecs/aws | ~> 5 |
| <a name="module_ecs_service_sg"></a> [ecs\_service\_sg](#module\_ecs\_service\_sg) | terraform-aws-modules/security-group/aws | ~> 5 |
| <a name="module_ollama_ecs_service"></a> [ollama\_ecs\_service](#module\_ollama\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | ~> 5 |
| <a name="module_tls"></a> [tls](#module\_tls) | terraform-aws-modules/acm/aws | ~> 4 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_fleet.spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_fleet) | resource |
| [aws_iam_instance_profile.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_instance_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_iam_policy_document.ecs_instance_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_ssm_parameter.ami_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [http_http.ollama_model_manifest](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_inbound_cidrs"></a> [alb\_inbound\_cidrs](#input\_alb\_inbound\_cidrs) | List of CIDR blocks to allow inbound traffic to the ALB | `list(string)` | `[]` | no |
| <a name="input_gpu_brand"></a> [gpu\_brand](#input\_gpu\_brand) | GPU brand to use for EC2 instances | `string` | `"nvidia"` | no |
| <a name="input_ollama_model"></a> [ollama\_model](#input\_ollama\_model) | Ollama model to use for the application | `string` | `"llama3:8b"` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | List of private subnet IDs to use for the application; the first one will be used for the EC2 instance | `list(string)` | `[]` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | List of public subnet IDs to use for the load balancer | `list(string)` | `[]` | no |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Route53 zone name to use for the application | `string` | n/a | yes |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain to use for the application; will be appended to the Route53 zone name | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_use_spot"></a> [use\_spot](#input\_use\_spot) | Whether to use spot instances for the EC2 instance | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/thezmc/terraform-aws-ecs-ollama/blob/main/LICENSE).

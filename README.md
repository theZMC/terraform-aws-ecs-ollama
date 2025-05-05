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

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 9.0 |
| <a name="module_alb_sg"></a> [alb\_sg](#module\_alb\_sg) | terraform-aws-modules/security-group/aws | ~> 5 |
| <a name="module_asg"></a> [asg](#module\_asg) | terraform-aws-modules/autoscaling/aws | ~> 7 |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | terraform-aws-modules/ecs/aws | ~> 5 |
| <a name="module_ecs_service_sg"></a> [ecs\_service\_sg](#module\_ecs\_service\_sg) | terraform-aws-modules/security-group/aws | ~> 5 |
| <a name="module_logging_bucket"></a> [logging\_bucket](#module\_logging\_bucket) | terraform-aws-modules/s3-bucket/aws | ~> 4 |
| <a name="module_ollama_ecs_service"></a> [ollama\_ecs\_service](#module\_ollama\_ecs\_service) | terraform-aws-modules/ecs/aws//modules/service | ~> 5 |
| <a name="module_tls"></a> [tls](#module\_tls) | terraform-aws-modules/acm/aws | ~> 4 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 5 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.webui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.basic_auth](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_efs_file_system.ollama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.ollama](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_ec2_managed_prefix_list.cloudfront](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_route53_zone.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_ssm_parameter.ami_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_inbound_cidrs"></a> [alb\_inbound\_cidrs](#input\_alb\_inbound\_cidrs) | List of CIDR blocks to allow inbound traffic to the ALB | `list(string)` | `[]` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones. If not provided, the first two available AZs will be used. | `list(string)` | `[]` | no |
| <a name="input_basic_auth_password"></a> [basic\_auth\_password](#input\_basic\_auth\_password) | Password for basic auth to use with the cloudfront distribution | `string` | n/a | yes |
| <a name="input_basic_auth_username"></a> [basic\_auth\_username](#input\_basic\_auth\_username) | Username for basic auth to use with the cloudfront distribution | `string` | n/a | yes |
| <a name="input_gpu_brand"></a> [gpu\_brand](#input\_gpu\_brand) | GPU brand to use for EC2 instances | `string` | `"nvidia"` | no |
| <a name="input_gpu_memory_mb"></a> [gpu\_memory\_mb](#input\_gpu\_memory\_mb) | Minimum amount of GPU memory in MB to use for EC2 instances | `number` | `16384` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | Route53 zone name to use for the application | `string` | n/a | yes |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain to use for the application; will be appended to the Route53 zone name | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/thezmc/terraform-aws-ecs-ollama/blob/main/LICENSE).

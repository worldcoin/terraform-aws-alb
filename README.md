# terraform-aws-alb

The module code is based on github.com/worldcoin/terraform-aws-nlb

## Example
```terraform
module "alb" {
  source = "github.com/worldcoin/terraform-aws-alb?ref=v0.1.0"

  cluster_name = var.name
  application  = "traefik/traefik"
  ingress_name = "traefik"
  internal     = false

  acm_arn        = var.acm_arn
  acm_extra_arns = var.acm_extra_arns
  vpc_id         = var.vpc_config.vpc_id
  public_subnets = var.vpc_config.public_subnets
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 4.10 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.additional_ports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.alb_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [cloudflare_ip_ranges.cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_arn"></a> [acm\_arn](#input\_acm\_arn) | ARN for ACM certificate used for TLS | `string` | n/a | yes |
| <a name="input_acm_extra_arns"></a> [acm\_extra\_arns](#input\_acm\_extra\_arns) | ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB | `list(string)` | `[]` | no |
| <a name="input_additional_open_ports"></a> [additional\_open\_ports](#input\_additional\_open\_ports) | Additional ports accessible from the Internet for the ALB | <pre>set(object({<br>    port     = number<br>    protocol = optional(string, "tcp")<br>  }))</pre> | `[]` | no |
| <a name="input_application"></a> [application](#input\_application) | Name of application which will be connected to this ALB | `string` | n/a | yes |
| <a name="input_backend_ingress_rules"></a> [backend\_ingress\_rules](#input\_backend\_ingress\_rules) | The security group rules to allow ingress from. | <pre>set(object({<br>    description     = optional(string, "")<br>    protocol        = optional(string, "tcp")<br>    port            = optional(number, 443)<br>    security_groups = optional(list(string))<br>    cidr_blocks     = optional(list(string))<br>  }))</pre> | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster will be used as suffix to all resources | `string` | n/a | yes |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Set NLB to be internal (available only within VPC) | `bool` | n/a | yes |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Part of the name used to differentiate NLBs for multiple traefik instances | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Name of namespace where application is deployed | `string` | n/a | yes |
| <a name="input_open_to_all"></a> [open\_to\_all](#input\_open\_to\_all) | Allow all traffic to the ALB | `bool` | `false` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of public subnets to use | `list(string)` | n/a | yes |
| <a name="input_s3_logs_bucket_id"></a> [s3\_logs\_bucket\_id](#input\_s3\_logs\_bucket\_id) | The ID of S3 bucket where the ALB logs will be stored, enables logging if set | `string` | `null` | no |
| <a name="input_tls_listener_version"></a> [tls\_listener\_version](#input\_tls\_listener\_version) | Minimum TLS version served by TLS listener | `string` | `"1.3"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the NLB will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the NLB. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the NLB. |
| <a name="output_sg_ids"></a> [sg\_ids](#output\_sg\_ids) | Security Group attached to loadbalancer |
| <a name="output_ssl_policy"></a> [ssl\_policy](#output\_ssl\_policy) | SSL Policy attached to loadbalancer |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The zone ID of the NLB. |
<!-- END_TF_DOCS -->

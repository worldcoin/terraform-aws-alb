# terraform-aws-alb

The module code is based on github.com/worldcoin/terraform-aws-nlb

## Example

```terraform
module "alb" {
  source = "github.com/worldcoin/terraform-aws-alb?ref=v1.1.0"

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

When `create_default_listener = false`, `acm_arn` can be omitted:

```terraform
module "alb" {
  source = "github.com/worldcoin/terraform-aws-alb?ref=v1.6.0"

  cluster_name             = var.name
  application              = "gateway-api/gateway"
  ingress_name             = "gateway"
  internal                 = false
  create_default_listener  = false

  vpc_id         = var.vpc_config.vpc_id
  public_subnets = var.vpc_config.public_subnets
}
```

## mTLS (Mutual TLS)

By default mTLS for ALB listener is enable with this module.
If you want to disable it set variable to false

- `mtls_enabled = false`

### WAF

You can override default rules using `waf_rules`

WAF rules are defined as default, if you want to add custom managed WAF rules you need to create your own file due to restrictions in creation of custom rules.
If you create your own WAF resource you need to deattach WAF rules created in this module.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | >= 5.8 |
| <a name="requirement_datadog"></a> [datadog](#requirement\_datadog) | >= 3.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | >= 5.8 |
| <a name="provider_datadog"></a> [datadog](#provider\_datadog) | >= 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.tls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_certificate.extra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_trust_store.root_ca](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_trust_store) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.alb_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [datadog_monitor.traefik_alb_client_tls_negotiation](https://registry.terraform.io/providers/DataDog/datadog/latest/docs/resources/monitor) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_vpc.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [cloudflare_ip_ranges.cloudflare](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/data-sources/ip_ranges) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_acm_arn"></a> [acm\_arn](#input\_acm\_arn) | ARN for ACM certificate used for TLS. Required when create\_default\_listener is true. | `string` | `null` | no |
| <a name="input_acm_extra_arns"></a> [acm\_extra\_arns](#input\_acm\_extra\_arns) | ARNs of ACM certificates used for TLS, attached as additional certificates to the main NLB | `list(string)` | `[]` | no |
| <a name="input_additional_open_ports"></a> [additional\_open\_ports](#input\_additional\_open\_ports) | Additional ports accessible from the Internet for the ALB | <pre>set(object({<br/>    port     = number<br/>    protocol = optional(string, "tcp")<br/>  }))</pre> | `[]` | no |
| <a name="input_application"></a> [application](#input\_application) | Name of application which will be connected to this ALB | `string` | n/a | yes |
| <a name="input_backend_ingress_rules"></a> [backend\_ingress\_rules](#input\_backend\_ingress\_rules) | The security group rules to allow ingress from. | <pre>set(object({<br/>    description     = optional(string, "")<br/>    protocol        = optional(string, "tcp")<br/>    port            = optional(number, 443)<br/>    security_groups = optional(list(string))<br/>    cidr_blocks     = optional(list(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the cluster will be used as suffix to all resources | `string` | n/a | yes |
| <a name="input_cluster_tag"></a> [cluster\_tag](#input\_cluster\_tag) | Value for the elbv2.k8s.aws/cluster tag. Defaults to cluster\_name. Use when the tag must differ from the name used to construct the LB name (e.g. Gateway API where the LB name prefix is trimmed but the tag must match the LBC --cluster-name). | `string` | `""` | no |
| <a name="input_create_default_listener"></a> [create\_default\_listener](#input\_create\_default\_listener) | Create the default HTTPS listener on port 443. Set to false when the listener is managed externally (e.g. by the AWS Gateway API controller). | `bool` | `true` | no |
| <a name="input_datadog"></a> [datadog](#input\_datadog) | Datadog configuration | <pre>object({<br/>    monitoring_notification_channel  = string<br/>    client_tls_negotiation_threshold = optional(number, 5)<br/>  })</pre> | `null` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Drop invalid header fields | `bool` | `true` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled via the AWS API | `bool` | `true` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | Set NLB to be internal (available only within VPC) | `bool` | n/a | yes |
| <a name="input_mtls_enabled"></a> [mtls\_enabled](#input\_mtls\_enabled) | Enable mutual TLS (mTLS) on the ALB TLS listener | `bool` | `true` | no |
| <a name="input_mtls_s3_bucket"></a> [mtls\_s3\_bucket](#input\_mtls\_s3\_bucket) | S3 bucket where the CA certificates for mTLS are stored | `string` | `"wld-mtls-ca-us-east-1"` | no |
| <a name="input_mtls_s3_key"></a> [mtls\_s3\_key](#input\_mtls\_s3\_key) | S3 key where the CA certificates for mTLS are stored | `string` | `"ca_cert/RootCA.pem"` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Part of the name used to differentiate NLBs for multiple traefik instances | `string` | `""` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Name of namespace where application is deployed | `string` | n/a | yes |
| <a name="input_open_to_all"></a> [open\_to\_all](#input\_open\_to\_all) | Allow all traffic to the ALB | `bool` | `false` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | List of public subnets to use | `list(string)` | n/a | yes |
| <a name="input_s3_logs_bucket_id"></a> [s3\_logs\_bucket\_id](#input\_s3\_logs\_bucket\_id) | The ID of S3 bucket where the ALB logs will be stored, enables logging if set | `string` | `null` | no |
| <a name="input_tag_prefix"></a> [tag\_prefix](#input\_tag\_prefix) | Tag key prefix for LBC resource/stack tags (e.g. ingress.k8s.aws for Ingress, gateway.k8s.aws.alb for Gateway API) | `string` | `"ingress.k8s.aws"` | no |
| <a name="input_tag_stack"></a> [tag\_stack](#input\_tag\_stack) | Override the computed stack tag value (default: namespace.application) | `string` | `""` | no |
| <a name="input_tls_listener_version"></a> [tls\_listener\_version](#input\_tls\_listener\_version) | Minimum TLS version served by TLS listener | `string` | `"1.3"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the NLB will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the NLB. |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the NLB. |
| <a name="output_listener_arn"></a> [listener\_arn](#output\_listener\_arn) | The ARN of the ALB default listener. |
| <a name="output_sg_ids"></a> [sg\_ids](#output\_sg\_ids) | Security Group attached to loadbalancer |
| <a name="output_ssl_policy"></a> [ssl\_policy](#output\_ssl\_policy) | SSL Policy attached to loadbalancer |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The zone ID of the NLB. |
<!-- END_TF_DOCS -->

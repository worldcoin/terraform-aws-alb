locals {
  waf_rules = length(var.waf_rules) != 0 ? var.waf_rules : [
    {
      name                                     = "AWSManagedRulesCommonRuleSet"
      priority                                 = 0
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesKnownBadInputsRuleSet"
      priority                                 = 1
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesAmazonIpReputationList"
      priority                                 = 2
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesAnonymousIpList"
      priority                                 = 3
      managed_rule_group_statement_vendor_name = "AWS"
    },
    {
      name                                     = "AWSManagedRulesSQLiRuleSet"
      priority                                 = 4
      managed_rule_group_statement_vendor_name = "AWS"
    }
  ]
}

resource "aws_wafv2_web_acl" "alb_waf" {
  count = var.waf_enabled ? 1 : 0
  name  = format("%s-waf", local.name)
  scope = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = format("%s-alb-waf", local.name)
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = toset(local.waf_rules)
    content {
      name     = rule.value.name
      priority = rule.value.priority
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.managed_rule_group_statement_vendor_name
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = format("%s-alb-waf-%s", local.name, rule.value.name)
        sampled_requests_enabled   = true
      }
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_enabled ? 1 : 0
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf[0].arn
}

module "s3_alb_waf_logs" {
  count  = var.waf_enabled ? 1 : 0
  source = "git@github.com:worldcoin/terraform-aws-s3-bucket?ref=v0.3.2"
  name   = format("aws-waf-logs-%s-%s", local.name, data.aws_region.current.name)
}

resource "aws_wafv2_web_acl_logging_configuration" "logs_to_s3" {
  count = var.waf_enabled ? 1 : 0

  log_destination_configs = [module.s3_alb_waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.alb_waf[0].arn
}

module "aws_dd_forwarder_lambda" {
  count = var.waf_enabled ? 1 : 0

  source           = "git@github.com:worldcoin/terraform-aws-modules.git//dd-forwarder-lambda?ref=v2.1.2"
  environment      = "stage"
  lambda_s3_bucket = module.s3_alb_waf_logs[0].name
  account_name     = "orb"

  datadog_api_key = var.datadog_api_key
}

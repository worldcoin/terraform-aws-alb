locals {
  waf_rules = var.empty_waf_rules ? [] : (length(var.waf_rules) != 0 ? var.waf_rules : [
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
  ])
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
  count         = var.waf_enabled ? 1 : 0
  source        = "git@github.com:worldcoin/terraform-aws-s3-bucket?ref=v0.3.2"
  name          = format("aws-waf-logs-%s-%s", local.name, data.aws_region.current.name)
  custom_policy = data.aws_iam_policy_document.allow_s3_logging.json
}

resource "aws_wafv2_web_acl_logging_configuration" "logs_to_s3" {
  count = var.waf_enabled ? 1 : 0

  log_destination_configs = [module.s3_alb_waf_logs[0].arn]
  resource_arn            = aws_wafv2_web_acl.alb_waf[0].arn
}

data "aws_iam_policy_document" "allow_s3_logging" {
  statement {
    sid       = "AWSLogDeliveryWrite"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${module.s3_alb_waf_logs[0].name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }

  statement {
    sid       = "AWSLogDeliveryAclCheck"
    effect    = "Allow"
    resources = [module.s3_alb_waf_logs[0].arn]
    actions   = ["s3:GetBucketAcl"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}

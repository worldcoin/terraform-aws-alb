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
    for_each = toset(var.waf_rules)
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
  custom_policy = data.aws_iam_policy_document.s3_logging.json
}

# https://docs.aws.amazon.com/waf/latest/developerguide/logging-s3.html#logging-s3-permissions
data "aws_iam_policy_document" "s3_logging" {
  statement {
    sid       = "LoggingConfigurationAPI"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "wafv2:PutLoggingConfiguration",
      "wafv2:DeleteLoggingConfiguration",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "WebACLLogDelivery"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogDelivery",
      "logs:DeleteLogDelivery",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid       = "WebACLLoggingS3"
    effect    = "Allow"
    resources = ["arn:aws:s3:::aws-waf-logs-${local.name}"]

    actions = [
      "s3:PutBucketPolicy",
      "s3:GetBucketPolicy",
    ]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "logs_to_s3" {
  count = var.waf_enabled ? 1 : 0

  log_destination_configs = [module.s3_alb_waf_logs[0].name]
  resource_arn            = aws_wafv2_web_acl.alb_waf[0].arn
}

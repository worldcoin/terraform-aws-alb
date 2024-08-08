resource "aws_wafv2_web_acl" "this" {
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
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = format("%s-alb-waf-AWSManagedRulesCommonRuleSet", local.name)
    sampled_requests_enabled   = true
  }
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-alb-waf-AWSManagedRulesKnownBadInputsRuleSet", local.name)
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-alb-waf-AWSManagedRulesAmazonIpReputationList", local.name)
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = format("%s-alb-waf-AWSManagedRulesAnonymousIpList", local.name)
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_enabled ? 1 : 0
  resource_arn = aws_lb.alb.arn
  web_acl_arn  = aws_wafv2_web_acl.alb_waf[0].arn
}

# Optional Lambda backends attached to the default TLS listener (var.lambda_targets).
# The AWS Load Balancer Controller does not manage Lambda targets, so when a caller
# wants a Lambda behind this ALB these resources wire it directly: a lambda-type
# target group, an ELB invoke permission, the attachment, and a listener rule that
# matches the given host/path conditions. Requires create_default_listener = true.

resource "aws_lb_target_group" "lambda" {
  for_each = var.lambda_targets

  name        = trimsuffix(substr("${local.alb_name}-${each.key}", 0, 32), "-")
  target_type = "lambda"

  tags = {
    "elbv2.k8s.aws/cluster"      = local.cluster_tag
    "${var.tag_prefix}/resource" = "lambda-${each.key}"
    "${var.tag_prefix}/stack"    = local.stack
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lambda_permission" "alb" {
  for_each = var.lambda_targets

  statement_id  = "AllowExecutionFromALB-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda[each.key].arn
}

resource "aws_lb_target_group_attachment" "lambda" {
  for_each = var.lambda_targets

  target_group_arn = aws_lb_target_group.lambda[each.key].arn
  target_id        = each.value.function_arn

  # The invoke permission must exist before the target group can register the function.
  depends_on = [aws_lambda_permission.alb]
}

resource "aws_lb_listener_rule" "lambda" {
  for_each = var.lambda_targets

  listener_arn = one(aws_lb_listener.tls[*].arn)
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda[each.key].arn
  }

  dynamic "condition" {
    for_each = each.value.host_headers != null ? [each.value.host_headers] : []
    content {
      host_header {
        values = condition.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.path_patterns != null ? [each.value.path_patterns] : []
    content {
      path_pattern {
        values = condition.value
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.create_default_listener
      error_message = "lambda_targets requires create_default_listener = true (rules attach to the default TLS listener)."
    }
  }
}

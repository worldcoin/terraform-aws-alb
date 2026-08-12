# Mock (offline) providers
mock_provider "aws" {
  source = "./tests/mocks/aws" # Path to the directory containing the mock files
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare" # Path to the directory containing the mock files
}

mock_provider "datadog" {}

run "default_tags" {
  command = plan

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "Default elbv2.k8s.aws/cluster tag should equal cluster_name when var.tags is empty"
  }

  assert {
    condition     = aws_lb.alb.tags["ingress.k8s.aws/resource"] == "LoadBalancer"
    error_message = "Default resource tag missing from ALB tags"
  }

  assert {
    condition     = aws_lb.alb.tags["ingress.k8s.aws/stack"] == "${var.namespace}.${var.application}"
    error_message = "Default stack tag missing from ALB tags"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "Listener should carry the same default cluster tag as the ALB"
  }
}

run "override_removes_default_cluster_tag_value" {
  command = plan

  variables {
    tags = {
      "elbv2.k8s.aws/cluster" = ""
    }
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == ""
    error_message = "var.tags should override the default elbv2.k8s.aws/cluster value"
  }

  assert {
    condition     = aws_lb.alb.tags["ingress.k8s.aws/resource"] == "LoadBalancer"
    error_message = "Overriding one default tag key must not remove the other module defaults"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags["elbv2.k8s.aws/cluster"] == ""
    error_message = "Listener's cluster tag should also be overridden"
  }
}

run "additional_tag_is_merged_alongside_defaults" {
  command = plan

  variables {
    tags = {
      Team = "infrastructure"
    }
  }

  assert {
    condition     = aws_lb.alb.tags["Team"] == "infrastructure"
    error_message = "A new tag key in var.tags should be added alongside the module defaults"
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "Adding a new tag key must not disturb the existing defaults"
  }
}

run "cluster_tag_variable_still_feeds_the_default" {
  command = plan

  variables {
    cluster_tag = "custom-cluster-tag"
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == "custom-cluster-tag"
    error_message = "var.cluster_tag should still set the default value that var.tags then merges over"
  }
}

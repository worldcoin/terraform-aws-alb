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

run "override_omits_default_cluster_tag_key" {
  command = plan

  variables {
    tags = {
      "elbv2.k8s.aws/cluster" = ""
    }
  }

  assert {
    condition     = !contains(keys(aws_lb.alb.tags), "elbv2.k8s.aws/cluster")
    error_message = "Setting var.tags[\"elbv2.k8s.aws/cluster\"] to \"\" should omit the key entirely, not just blank its value"
  }

  assert {
    condition     = aws_lb.alb.tags["ingress.k8s.aws/resource"] == "LoadBalancer"
    error_message = "Overriding one default tag key must not remove the other module defaults"
  }

  assert {
    condition     = !contains(keys(aws_lb_listener.tls[0].tags), "elbv2.k8s.aws/cluster")
    error_message = "Listener's cluster tag key should also be omitted"
  }
}

run "null_tags_falls_back_to_defaults" {
  command = plan

  variables {
    tags = null
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "nullable = false should substitute the default {} when var.tags is null, not error or drop the defaults"
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

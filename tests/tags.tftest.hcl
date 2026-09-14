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

run "tags_fully_replace_defaults" {
  command = plan

  variables {
    tags = {
      Team = "infrastructure"
    }
  }

  assert {
    condition     = aws_lb.alb.tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the ALB, not merge with them"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags == tomap({ Team = "infrastructure" })
    error_message = "Non-empty var.tags should fully replace the module's default tags on the listener, not merge with them"
  }
}

run "null_tags_falls_back_to_defaults" {
  command = plan

  variables {
    tags = null
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == var.cluster_name
    error_message = "var.tags = null should behave like the {} default (nullable = false), not error or omit defaults"
  }
}

run "cluster_tag_variable_still_feeds_the_default" {
  command = plan

  variables {
    cluster_tag = "custom-cluster-tag"
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == "custom-cluster-tag"
    error_message = "var.cluster_tag should still set the default elbv2.k8s.aws/cluster value when var.tags is empty"
  }
}

run "backend_egress_includes_vpc_ipv6_cidr_associations" {
  command = plan

  assert {
    condition     = toset(one(aws_security_group.alb_backend.egress).ipv6_cidr_blocks) == toset(["2600:1f14:abcd:1000::/56", "2600:1f14:abcd:2000::/56"])
    error_message = "Backend egress should include every IPv6 CIDR associated with the VPC"
  }
}

run "backend_ingress_accepts_ipv6_cidr_blocks" {
  command = plan

  variables {
    backend_ingress_rules = [{
      description      = "Allow HTTPS from VPC IPv6"
      port             = 443
      ipv6_cidr_blocks = ["2600:1f14:abcd:1000::/56", "2600:1f14:abcd:2000::/56"]
    }]
  }

  assert {
    condition     = toset(one([for ingress in aws_security_group.alb_backend.ingress : ingress if ingress.description == "Allow HTTPS from VPC IPv6"]).ipv6_cidr_blocks) == toset(["2600:1f14:abcd:1000::/56", "2600:1f14:abcd:2000::/56"])
    error_message = "Backend ingress rules should forward IPv6 CIDR blocks to the security group"
  }
}

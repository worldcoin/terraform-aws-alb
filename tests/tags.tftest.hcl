# Mock (offline) providers
mock_provider "aws" {
  source = "./tests/mocks/aws" # Path to the directory containing the mock files
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare" # Path to the directory containing the mock files
}

mock_provider "datadog" {}

run "standalone_alb_omits_cluster_tag" {
  command = plan

  assert {
    condition     = !contains(keys(aws_lb.alb.tags), "elbv2.k8s.aws/cluster")
    error_message = "Standalone ALBs must not inherit an EKS cluster tag from cluster_name"
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
    condition     = !contains(keys(aws_lb_listener.tls[0].tags), "elbv2.k8s.aws/cluster")
    error_message = "Standalone ALB listeners must not carry an EKS cluster tag"
  }
}

run "tags_fully_replace_defaults" {
  command = plan

  variables {
    cluster_tag = "eks-cluster"
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
    condition     = aws_lb.alb.tags == tomap({ "ingress.k8s.aws/resource" = "LoadBalancer", "ingress.k8s.aws/stack" = "${var.namespace}.${var.application}" })
    error_message = "Null tags must use the standalone defaults without an EKS cluster tag"
  }
}

run "eks_cluster_tag_is_explicit" {
  command = plan

  variables {
    cluster_tag = "custom-cluster-tag"
    tag_prefix  = "gateway.k8s.aws.alb"
    tag_stack   = "kube-system/gw-ext-alb"
  }

  assert {
    condition     = aws_lb.alb.tags["elbv2.k8s.aws/cluster"] == "custom-cluster-tag"
    error_message = "EKS ALBs must use the explicit cluster_tag instead of the resource naming prefix"
  }

  assert {
    condition     = aws_lb_listener.tls[0].tags["elbv2.k8s.aws/cluster"] == "custom-cluster-tag"
    error_message = "EKS listeners must carry the explicit cluster tag"
  }

  assert {
    condition     = aws_lb.alb.tags["gateway.k8s.aws.alb/stack"] == "kube-system/gw-ext-alb" && aws_lb.alb.tags["gateway.k8s.aws.alb/resource"] == "LoadBalancer"
    error_message = "Explicit cluster tagging must preserve Gateway API resource and stack tags"
  }

  assert {
    condition     = aws_lb.alb.name == "test-cluster"
    error_message = "The cluster tag must not change the ALB resource name"
  }
}

run "null_cluster_tag_omits_cluster_tracking" {
  command = plan

  variables {
    cluster_tag = null
  }

  assert {
    condition     = !contains(keys(aws_lb.alb.tags), "elbv2.k8s.aws/cluster") && !contains(keys(aws_lb_listener.tls[0].tags), "elbv2.k8s.aws/cluster")
    error_message = "A null cluster_tag must omit EKS tracking on both the ALB and listener"
  }
}

run "existing_alb_with_cluster_tag" {
  command = apply

  variables {
    cluster_tag = "test-cluster-us-east-1"
  }

  override_resource {
    target = aws_lb.alb
    values = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-cluster/0123456789abcdef"
    }
  }

  override_resource {
    target = aws_lb_trust_store.root_ca[0]
    values = {
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:truststore/test-cluster/0123456789abcdef"
    }
  }
}

run "remove_existing_cluster_tag" {
  command = plan

  assert {
    condition     = !contains(keys(aws_lb.alb.tags), "elbv2.k8s.aws/cluster") && !contains(keys(aws_lb_listener.tls[0].tags), "elbv2.k8s.aws/cluster")
    error_message = "Explicit tags must lose cluster tracking when an existing standalone ALB opts out"
  }

  assert {
    condition     = aws_lb.alb.arn == run.existing_alb_with_cluster_tag.arn && aws_lb_listener.tls[0].arn == run.existing_alb_with_cluster_tag.listener_arn
    error_message = "Removing the cluster tag must preserve the existing ALB and listener"
  }
}

run "backend_egress_includes_vpc_ipv6_cidr_associations" {
  command = plan

  assert {
    condition     = local.vpc_ipv6_cidr_blocks == tolist(["2600:1f14:abcd:1000::/56", "2600:1f14:abcd:2000::/56"])
    error_message = "Backend egress should include active VPC IPv6 CIDRs in deterministic order"
  }

  assert {
    condition     = toset(one(aws_security_group.alb_backend.egress).ipv6_cidr_blocks) == toset(["2600:1f14:abcd:1000::/56", "2600:1f14:abcd:2000::/56"])
    error_message = "Backend egress should exclude inactive VPC IPv6 CIDR associations"
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

run "backend_ingress_allows_omitted_ipv6_cidr_blocks" {
  command = plan

  variables {
    backend_ingress_rules = [
      {
        description = "Allow HTTPS from IPv4"
        port        = 443
        cidr_blocks = ["10.0.0.0/8"]
      },
      {
        description      = "Allow HTTPS from security group"
        port             = 443
        security_groups  = ["sg-0123456789abcdef0"]
        ipv6_cidr_blocks = null
      },
    ]
  }

  assert {
    condition     = alltrue([for ingress in aws_security_group.alb_backend.ingress : ingress.description == "Allow HTTPS from IPv4" || ingress.description == "Allow HTTPS from security group" ? ingress.ipv6_cidr_blocks == null : true])
    error_message = "Existing backend ingress rules should work when IPv6 CIDR blocks are omitted or null"
  }
}

run "security_group_rules_have_descriptions" {
  command = plan

  variables {
    additional_open_ports = [{ port = 80 }]
    backend_ingress_rules = [
      {
        port        = 8443
        cidr_blocks = ["10.0.0.0/16"]
      },
      {
        description = "Allow health checks"
        port        = 8080
        cidr_blocks = ["10.0.0.0/16"]
      },
    ]
  }

  assert {
    condition = alltrue(concat(
      [for rule in aws_security_group.alb[0].ingress : length(trimspace(rule.description)) > 0],
      [for rule in aws_security_group.alb[0].egress : length(trimspace(rule.description)) > 0],
      [for rule in aws_security_group.alb_backend.ingress : length(trimspace(rule.description)) > 0],
      [for rule in aws_security_group.alb_backend.egress : length(trimspace(rule.description)) > 0],
    ))
    error_message = "Every ALB security group rule should have a description"
  }

  assert {
    condition     = one([for rule in aws_security_group.alb_backend.ingress : rule.description if rule.from_port == 8443]) == "Allow TCP/8443 to ALB"
    error_message = "Backend rules without a caller description should receive a useful default"
  }

  assert {
    condition     = one([for rule in aws_security_group.alb_backend.ingress : rule.description if rule.from_port == 8080]) == "Allow health checks"
    error_message = "Caller-provided backend rule descriptions should be preserved"
  }
}

run "public_ingress_descriptions_reflect_open_source" {
  command = plan

  variables {
    open_to_all           = true
    additional_open_ports = [{ port = 80 }]
  }

  assert {
    condition     = alltrue([for rule in aws_security_group.alb[0].ingress : strcontains(rule.description, "any IPv")])
    error_message = "Public ingress descriptions should identify their open IPv4 or IPv6 source"
  }
}

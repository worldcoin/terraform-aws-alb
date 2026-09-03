# Mock (offline) providers
mock_provider "aws" {
  source = "./tests/mocks/aws"
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare"
}

mock_provider "datadog" {}

run "default_is_cloudflare_only" {
  command = plan

  assert {
    condition = anytrue([
      for rule in aws_security_group.alb[0].ingress :
      rule.from_port == 443 && try(contains(rule.cidr_blocks, "173.245.48.0/20"), false)
    ])
    error_message = "Without frontend_ingress_cidrs the 443 IPv4 rule should allow the Cloudflare ranges"
  }

  assert {
    condition = anytrue([
      for rule in aws_security_group.alb[0].ingress :
      rule.from_port == 443 && try(contains(rule.ipv6_cidr_blocks, "2400:cb00::/32"), false)
    ])
    error_message = "Without frontend_ingress_cidrs a 443 IPv6 rule for the Cloudflare ranges should exist"
  }
}

run "allowlist_replaces_cloudflare_sources" {
  command = plan

  variables {
    frontend_ingress_cidrs = ["203.0.113.7/32", "198.51.100.0/24"]
  }

  assert {
    condition = anytrue([
      for rule in aws_security_group.alb[0].ingress :
      rule.from_port == 443 && try(sort(rule.cidr_blocks) == sort(["203.0.113.7/32", "198.51.100.0/24"]), false)
    ])
    error_message = "frontend_ingress_cidrs should be the only IPv4 sources on the 443 rule"
  }

  assert {
    condition = !anytrue([
      for rule in aws_security_group.alb[0].ingress :
      try(contains(rule.cidr_blocks, "173.245.48.0/20"), false) || try(contains(rule.ipv6_cidr_blocks, "2400:cb00::/32"), false)
    ])
    error_message = "With frontend_ingress_cidrs set, no Cloudflare IPv4/IPv6 sources may remain"
  }
}

run "allowlist_rejects_open_to_all" {
  command = plan

  variables {
    frontend_ingress_cidrs = ["203.0.113.7/32"]
    open_to_all            = true
  }

  expect_failures = [var.frontend_ingress_cidrs]
}

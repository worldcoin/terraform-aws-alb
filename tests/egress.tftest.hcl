mock_provider "aws" {
  source = "./tests/mocks/aws"
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare"
}

mock_provider "datadog" {}

run "default_relies_on_backend_vpc_egress" {
  command = plan

  assert {
    condition     = length(aws_security_group.alb[0].egress) == 0
    error_message = "Omitted rules must leave internet-SG egress empty."
  }

  assert {
    condition     = length(aws_security_group.alb_backend.egress) == 1 && one(aws_security_group.alb_backend.egress).protocol == "-1" && toset(one(aws_security_group.alb_backend.egress).cidr_blocks) == toset([data.aws_vpc.current.cidr_block]) && toset(one(aws_security_group.alb_backend.egress).ipv6_cidr_blocks) == toset(local.vpc_ipv6_cidr_blocks)
    error_message = "The default must preserve all-port IPv4 and IPv6 backend VPC egress."
  }
}

run "null_inherits_restricted_default" {
  command = plan

  variables {
    internet_egress_sg_rules = null
  }

  assert {
    condition     = length(aws_security_group.alb[0].egress) == 0
    error_message = "Null must inherit empty internet-SG egress."
  }

  assert {
    condition     = length(aws_security_group.alb_backend.egress) == 1 && one(aws_security_group.alb_backend.egress).protocol == "-1" && toset(one(aws_security_group.alb_backend.egress).cidr_blocks) == toset([data.aws_vpc.current.cidr_block]) && toset(one(aws_security_group.alb_backend.egress).ipv6_cidr_blocks) == toset(local.vpc_ipv6_cidr_blocks)
    error_message = "The default must preserve all-port IPv4 and IPv6 backend VPC egress."
  }
}

run "empty_revokes_internet_egress_and_preserves_backend" {
  command = plan

  variables {
    internet_egress_sg_rules = []
  }

  assert {
    condition     = length(aws_security_group.alb[0].egress) == 0
    error_message = "An explicit empty collection must manage no internet SG outbound rules."
  }

  assert {
    condition     = toset(one(aws_security_group.alb_backend.egress).cidr_blocks) == toset([data.aws_vpc.current.cidr_block]) && toset(one(aws_security_group.alb_backend.egress).ipv6_cidr_blocks) == toset(local.vpc_ipv6_cidr_blocks)
    error_message = "The backend SG must preserve IPv4 and IPv6 VPC egress."
  }
}

run "explicit_external_destination_plans" {
  command = plan

  variables {
    internet_egress_sg_rules = [{
      description = "Allow external authentication endpoint"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      cidr_blocks = ["192.0.2.10/32"]
    }]
  }

  assert {
    condition     = length(aws_security_group.alb[0].egress) == 1 && one(aws_security_group.alb[0].egress).protocol == "tcp" && one(aws_security_group.alb[0].egress).from_port == 443 && one(aws_security_group.alb[0].egress).to_port == 443 && toset(one(aws_security_group.alb[0].egress).cidr_blocks) == toset(["192.0.2.10/32"])
    error_message = "Explicit rules must allow only the configured external destination."
  }
}

run "omitted_description_has_useful_fallback" {
  command = plan

  variables {
    internet_egress_sg_rules = [{
      protocol         = "tcp"
      from_port        = 8443
      to_port          = 8443
      ipv6_cidr_blocks = ["2001:db8::/64"]
    }]
  }

  assert {
    condition     = one(aws_security_group.alb[0].egress).description == "Allow TCP/8443-8443 to configured destinations"
    error_message = "Custom rules without descriptions must retain useful audit context."
  }
}

run "internal_alb_has_only_backend_sg" {
  command = plan

  variables {
    internal = true
  }

  assert {
    condition     = length(aws_security_group.alb) == 0 && length(aws_security_group.alb_backend.egress) == 1
    error_message = "Internet egress configuration must not create an internet SG or remove internal ALB backend egress."
  }
}

run "rejects_missing_destination" {
  command = plan

  variables {
    internet_egress_sg_rules = [{ protocol = "tcp", from_port = 443, to_port = 443 }]
  }

  expect_failures = [var.internet_egress_sg_rules]
}

run "rejects_null_rule" {
  command = plan

  variables {
    internet_egress_sg_rules = [null]
  }

  expect_failures = [var.internet_egress_sg_rules]
}

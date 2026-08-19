mock_data "aws_region" {
  defaults = {
    name   = "us-east-1"
    region = "us-east-1"
  }
}

mock_data "aws_vpc" {
  defaults = {
    id              = "vpc-1234567890abcdef0"
    cidr_block      = "10.0.0.0/16"
    ipv6_cidr_block = ""
  }
}

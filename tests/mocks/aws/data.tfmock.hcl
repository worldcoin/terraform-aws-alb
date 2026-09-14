mock_data "aws_region" {
  defaults = {
    name   = "us-east-1"
    region = "us-east-1"
  }
}

mock_data "aws_vpc" {
  defaults = {
    id         = "vpc-1234567890abcdef0"
    cidr_block = "10.0.0.0/16"
    ipv6_cidr_block_associations = [
      {
        association_id         = "vpc-cidr-assoc-1234567890abcdef0"
        ip_source              = "amazon"
        ipv6_address_attribute = "public"
        ipv6_cidr_block        = "2600:1f14:abcd:1000::/56"
        ipv6_pool              = "Amazon"
        network_border_group   = "us-east-1"
        state                  = "associated"
      },
      {
        association_id         = "vpc-cidr-assoc-abcdef0123456789"
        ip_source              = "amazon"
        ipv6_address_attribute = "public"
        ipv6_cidr_block        = "2600:1f14:abcd:2000::/56"
        ipv6_pool              = "Amazon"
        network_border_group   = "us-east-1"
        state                  = "associated"
      },
    ]
  }
}

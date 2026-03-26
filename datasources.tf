data "aws_region" "current" {}

data "aws_vpc" "current" {
  id = var.vpc_id
}

data "cloudflare_ip_ranges" "cloudflare" {}

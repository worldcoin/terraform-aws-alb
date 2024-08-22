data "aws_region" "current" {}

data "cloudflare_ip_ranges" "cloudflare" {}

data "aws_caller_identity" "current" {}

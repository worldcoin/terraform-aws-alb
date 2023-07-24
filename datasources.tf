data "aws_region" "current" {}
data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

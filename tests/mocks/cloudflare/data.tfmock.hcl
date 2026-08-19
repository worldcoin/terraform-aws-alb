mock_data "cloudflare_ip_ranges" {
  defaults = {
    ipv4_cidrs = ["173.245.48.0/20"]
    ipv6_cidrs = ["2400:cb00::/32"]
  }
}

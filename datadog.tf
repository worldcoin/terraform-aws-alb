resource "datadog_monitor" "traefik_alb_client_tls_negotiation" {
  count = var.mtls_enabled && var.datadog != null ? 1 : 0

  name    = format("ALB TLS negotiation errors (%s)", local.alb_name)
  type    = "metric alert"
  message = <<EOT
ALB client TLS negotiation errors exceed threshold (${var.datadog.client_tls_negotiation_threshold})

${var.datadog.monitoring_notification_channel}
EOT

  query = format(
    "avg(last_15m):sum:aws.applicationelb.client_tlsnegotiation_error_count{host:%s*} by {host}.as_rate() > %d",
    local.alb_name,
    var.datadog.client_tls_negotiation_threshold
  )

  priority            = 1
  require_full_window = false

  monitor_thresholds {
    critical = var.datadog.client_tls_negotiation_threshold
  }

  tags = [
    "CreatedBy:terraform",
    "team:infrastructure",
  ]
}

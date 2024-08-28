output "arn" {
  description = "The ARN of the NLB."
  value       = aws_lb.alb.arn
}

output "dns_name" {
  description = "The DNS name of the NLB."
  value       = aws_lb.alb.dns_name
}

output "zone_id" {
  description = "The zone ID of the NLB."
  value       = aws_lb.alb.zone_id
}

output "sg_ids" {
  description = "Security Group attached to loadbalancer"
  value = {
    backend  = aws_security_group.alb_backend.id
    internet = var.internal ? null : aws_security_group.alb[0].id
  }
}

output "ssl_policy" {
  description = "SSL Policy attached to loadbalancer"
  value       = aws_lb_listener.tls.ssl_policy
}

output "waf_arn" {
  description = "The ARN of the WAF."
  value       = var.waf_enabled ? aws_wafv2_web_acl.alb_waf[0].arn : null
}

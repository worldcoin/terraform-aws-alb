output "ready" {
  description = "Hack! Because modules with providers (cluster-apps) cannot use depends_on output value needs to be used to make sure those are provisioned in correct order."
  value = {
    tls = "${aws_lb_listener.tls.arn}:${aws_lb_target_group.tls.id}"
  }
}

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

output "sg_id" {
  description = "Security Group attached to loadbalancer"
  value       = aws_security_group.alb.id
}

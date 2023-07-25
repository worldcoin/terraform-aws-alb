locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.name}", "")
  name               = join("-", compact([local.short_cluster_name, var.name_suffix]))
  short_name         = substr(local.name, 0, 26) # Shorter name used to bypass 32 char limitation for target groups
  # / is not allowd by k8s anntotations to pick up existing LB
  stack            = format("%s.%s", var.namespace, var.application)
  target_group_tag = format("%s/%s-%s:443", var.namespace, var.ingress_name, var.application)
}

resource "aws_security_group" "alb" {
  name        = local.name
  description = "Security group attached to ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = data.cloudflare_ip_ranges.cloudflare.ipv4_cidr_blocks
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = data.cloudflare_ip_ranges.cloudflare.ipv6_cidr_blocks
  }
}

resource "aws_lb" "alb" {
  name                             = substr(local.name, 0, 32) # "name" cannot be longer than 32 characters
  internal                         = var.internal
  load_balancer_type               = "application"
  subnets                          = var.public_subnets
  security_groups                  = [aws_security_group.alb.id]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "LoadBalancer"
    "ingress.k8s.aws/stack"    = local.stack
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener" "tls" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tls.arn
  }

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "443"
    "ingress.k8s.aws/stack"    = local.stack
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_lb_listener_certificate" "extra" {
  count           = length(var.acm_extra_arns)
  listener_arn    = aws_lb_listener.tls.arn
  certificate_arn = element(var.acm_extra_arns, count.index)
}

resource "aws_lb_target_group" "tls" {
  name = "${local.short_name}-tls"
  port = 30443
  #we misconfigured something, and currently, traefik serves HTTP on the 443 port. Problem addresed here: https://linear.app/worldcoin/issue/INFRA-855/debug-ingress-websecure-with-http
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "instance"

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = local.target_group_tag
    "ingress.k8s.aws/stack"    = local.stack
  }

  stickiness {
    cookie_duration = 14400
    enabled         = false
    type            = "lb_cookie"
  }

  lifecycle {
    ignore_changes = [tags_all]
  }
}

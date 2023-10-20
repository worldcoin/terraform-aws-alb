locals {
  # cluter name without region
  short_cluster_name = replace(var.cluster_name, "-${data.aws_region.current.name}", "")
  name               = join("-", compact([local.short_cluster_name, var.name_suffix]))
  # / is not allowd by k8s anntotations to pick up existing LB
  stack = format("%s.%s", var.namespace, var.application)
}

resource "aws_security_group" "alb" {
  count       = var.internal ? 0 : 1
  name        = format("%s-internet", local.name)
  description = "SG attached to ALB exposing LB to the internet"
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

resource "aws_security_group" "alb_backend" {
  name        = format("%s-backend", local.name)
  description = "SG to provide network access inside VPC"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.backend_ingress_rules

    content {
      description     = ingress.value["description"]
      from_port       = ingress.value["port"]
      to_port         = ingress.value["port"]
      protocol        = ingress.value["protocol"]
      security_groups = ingress.value["security_groups"]
      cidr_blocks     = ingress.value["cidr_blocks"]
    }
  }
}

resource "aws_lb" "alb" {
  name               = substr(local.name, 0, 32) # "name" cannot be longer than 32 characters
  internal           = var.internal
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups = compact([
    var.internal ? "" : aws_security_group.alb[0].id,
    aws_security_group.alb_backend.id
  ])

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true

  access_logs {
    enabled = var.s3_logs_bucket_id != null ? true : false
    bucket  = var.s3_logs_bucket_id
    prefix  = var.cluster_name
  }

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

  tags = {
    "elbv2.k8s.aws/cluster"    = var.cluster_name
    "ingress.k8s.aws/resource" = "443"
    "ingress.k8s.aws/stack"    = local.stack
  }

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "404"
    }
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

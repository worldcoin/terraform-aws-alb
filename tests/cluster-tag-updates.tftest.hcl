mock_provider "aws" {
  alias  = "seed"
  source = "./tests/mocks/aws"

  mock_resource "aws_lb" {
    defaults = {
      id  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-cluster/0123456789abcdef"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-cluster/0123456789abcdef"
      tags_all = {
        "elbv2.k8s.aws/cluster"    = "test-cluster-us-east-1"
        "ingress.k8s.aws/resource" = "LoadBalancer"
        "ingress.k8s.aws/stack"    = "test-ns.test-app"
      }
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      id  = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/test-cluster/0123456789abcdef/0123456789abcdef"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/test-cluster/0123456789abcdef/0123456789abcdef"
      tags_all = {
        "elbv2.k8s.aws/cluster"    = "test-cluster-us-east-1"
        "ingress.k8s.aws/resource" = "443"
        "ingress.k8s.aws/stack"    = "test-ns.test-app"
      }
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id = "sg-0123456789abcdef0"
    }
  }
}

# Exercise the AWS provider's tags_all planning without AWS API access.
provider "aws" {
  alias                       = "offline"
  region                      = "us-east-1"
  access_key                  = "testing"
  secret_key                  = "testing"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  max_retries                 = 0

  endpoints {
    elbv2 = "http://127.0.0.1:9"
    ec2   = "http://127.0.0.1:9"
  }
}

mock_provider "cloudflare" {
  source = "./tests/mocks/cloudflare"
}

mock_provider "datadog" {}

variables {
  mtls_enabled = false
}

override_data {
  target = data.aws_region.current
  values = {
    name   = "us-east-1"
    region = "us-east-1"
  }
}

override_data {
  target = data.aws_vpc.current
  values = {
    id                           = "vpc-1234567890abcdef0"
    cidr_block                   = "10.0.0.0/16"
    ipv6_cidr_block_associations = []
  }
}

run "seed_existing_cluster_tags" {
  command = apply

  providers = {
    aws        = aws.seed
    cloudflare = cloudflare
    datadog    = datadog
  }

  variables {
    cluster_tag = "test-cluster-us-east-1"
  }
}

run "plan_existing_eks_tags_with_aws_provider" {
  command = plan

  providers = {
    aws        = aws.offline
    cloudflare = cloudflare
    datadog    = datadog
  }

  variables {
    cluster_tag = "test-cluster-us-east-1"
  }

  plan_options {
    refresh = false
  }

  assert {
    condition     = aws_lb.alb.tags_all["elbv2.k8s.aws/cluster"] == "test-cluster-us-east-1" && aws_lb_listener.tls[0].tags_all["elbv2.k8s.aws/cluster"] == "test-cluster-us-east-1"
    error_message = "Explicit EKS tracking must remain in the AWS provider's effective tags"
  }
}

run "plan_cluster_tag_removal_with_aws_provider" {
  command = plan

  providers = {
    aws        = aws.offline
    cloudflare = cloudflare
    datadog    = datadog
  }

  plan_options {
    refresh = false
  }

  assert {
    condition     = !contains(keys(aws_lb.alb.tags_all), "elbv2.k8s.aws/cluster")
    error_message = "The AWS provider's effective ALB tag set must remove the cluster tag"
  }

  assert {
    condition     = !contains(keys(aws_lb_listener.tls[0].tags_all), "elbv2.k8s.aws/cluster")
    error_message = "The AWS provider's effective listener tag set must remove the cluster tag"
  }
}

run "restore_mock_provider_for_cleanup" {
  command = plan

  providers = {
    aws        = aws.seed
    cloudflare = cloudflare
    datadog    = datadog
  }

  variables {
    cluster_tag = "test-cluster-us-east-1"
  }
}

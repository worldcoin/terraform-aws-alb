terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.14.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.1"
    }
  }

  required_version = ">= 1.0"
}

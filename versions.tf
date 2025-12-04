terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.14.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.8"
    }

    datadog = {
      source  = "DataDog/datadog"
      version = ">= 3.0"
    }
  }

  required_version = ">= 1.0"
}

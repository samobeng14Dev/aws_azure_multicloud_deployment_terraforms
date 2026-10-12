# Terraform provider requirements for the multi-cloud website deployment.
# AWS is used for the primary CloudFront/S3 stack, while Azure provides the failover site.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.68"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.9"
    }
  }
}

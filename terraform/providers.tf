# Providers for the multi-cloud deployment.
# AWS hosts the S3 and CloudFront primary site, while Azure hosts the failover website.
provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

# CloudFront certificates must be requested in us-east-1 because CloudFront is a global service.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
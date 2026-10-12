# Shared configuration values used across the AWS and Azure deployment resources.
# These values control the target regions, regional naming constraints, custom-domain setup,
# and the Route53 health check used for failover.

variable "aws_region" {
  description = "AWS region for the S3 bucket."
  type        = string
  default     = "eu-north-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the website."
  type        = string
}

variable "azure_location" {
  description = "Azure region for the resource group and storage account."
  type        = string
  default     = "North Europe"
}

variable "azure_storage_account_name" {
  description = "Globally unique Azure storage account name (3-24 chars, lowercase letters and digits only)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.azure_storage_account_name))
    error_message = "Use 3-24 characters: lowercase letters and digits only, no hyphens."
  }
}

variable "domain_name" {
  description = "Your registered domain, without www."
  type        = string
}

variable "enable_custom_domain" {
  description = "Stage switch: false = default CloudFront certificate, true = www custom domain with ACM certificate."
  type        = bool
  default     = false
}

variable "primary_health_check_path" {
  description = "Path the primary health check requests. Use a missing path to simulate an AWS outage."
  type        = string
  default     = "/"
}
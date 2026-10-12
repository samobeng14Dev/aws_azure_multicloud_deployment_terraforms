# Deployment endpoints and DNS values exported for use after Terraform apply.
# These outputs provide the direct URLs for each platform and the DNS details needed
# to complete the custom domain setup.

output "s3_website_url" {
  description = "Direct S3 static website endpoint over HTTP."
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

output "azure_website_url" {
  description = "Azure static website endpoint served over HTTPS."
  value       = azurerm_storage_account.storage.primary_web_endpoint
}

output "azure_website_host" {
  description = "Azure website hostname used as the secondary failover target."
  value       = azurerm_storage_account.storage.primary_web_host
}

output "cloudfront_url" {
  description = "Primary site URL served through CloudFront over HTTPS."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "route53_name_servers" {
  description = "Name servers to configure at the registrar for the custom domain."
  value       = aws_route53_zone.main.name_servers
}

output "site_url" {
  description = "Custom domain URL for the production website after DNS is configured."
  value       = "https://www.${var.domain_name}"
}
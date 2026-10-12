# DNS and failover configuration for the global website.
# This file creates the hosted zone, requests the public certificate, validates it,
# and routes traffic between the primary AWS endpoint and the secondary Azure endpoint.

locals {
  site_host = "www.${var.domain_name}"
}

# Hosted zone for the custom domain used by the site.
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# ACM certificate for the CloudFront custom domain. This certificate must be issued in us-east-1
# because CloudFront is a global AWS service and expects certificates in that region.
resource "aws_acm_certificate" "site" {
  count             = var.enable_custom_domain ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = local.site_host
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create the DNS validation records required to verify the ACM certificate.
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_custom_domain ? {
    for dvo in aws_acm_certificate.site[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# Wait for the ACM certificate to be valid before using it in CloudFront.
resource "aws_acm_certificate_validation" "site" {
  count                   = var.enable_custom_domain ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# Health checks allow Route53 to fail over automatically when the primary endpoint becomes unavailable.
resource "aws_route53_health_check" "primary" {
  type              = "HTTPS"
  fqdn              = aws_cloudfront_distribution.site.domain_name
  port              = 443
  resource_path     = var.primary_health_check_path
  request_interval  = 30
  failure_threshold = 3

  tags = { Name = "weather-primary-aws" }
}

resource "aws_route53_health_check" "secondary" {
  type              = "HTTPS"
  fqdn              = azurerm_storage_account.storage.primary_web_host
  port              = 443
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3

  tags = { Name = "weather-secondary-azure" }
}

# Route53 failover records share the same host name and type, but are distinguished by their set identifier.
# The primary record points to the AWS CloudFront distribution and the secondary record points to Azure.
resource "aws_route53_record" "primary" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = local.site_host
  type            = "CNAME"
  ttl             = 60
  records         = [aws_cloudfront_distribution.site.domain_name]
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id

  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "secondary" {
  zone_id         = aws_route53_zone.main.zone_id
  name            = local.site_host
  type            = "CNAME"
  ttl             = 60
  records         = [azurerm_storage_account.storage.primary_web_host]
  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.secondary.id

  failover_routing_policy {
    type = "SECONDARY"
  }
}

# Lets Azure verify that we own www.<domain> before it accepts requests for that name.
resource "aws_route53_record" "azure_asverify" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "asverify.www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = ["asverify.${var.azure_storage_account_name}.blob.core.windows.net"]
}
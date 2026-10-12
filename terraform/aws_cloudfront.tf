# CloudFront distribution for the static website.
# This layer serves the site globally over HTTPS, caches static content at the edge,
# and optionally uses a custom domain certificate when the domain is enabled.

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Attach the custom domain only when the user has enabled domain hosting.
  aliases = var.enable_custom_domain ? ["www.${var.domain_name}"] : []

  # The S3 website endpoint is configured for website hosting and only supports HTTP.
  # CloudFront therefore uses an HTTP origin connection while still serving HTTPS to viewers.
  origin {
    domain_name = aws_s3_bucket_website_configuration.site.website_endpoint
    origin_id   = "s3-website"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Serve the site with a simple, cache-friendly policy for static content.
  default_cache_behavior {
    target_origin_id       = "s3-website"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
  }

  # No geo-blocking restrictions are applied for this deployment.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use the default CloudFront certificate when no custom domain is configured.
  dynamic "viewer_certificate" {
    for_each = var.enable_custom_domain ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }

  # Use the ACM certificate and custom TLS settings when a custom domain is configured.
  dynamic "viewer_certificate" {
    for_each = var.enable_custom_domain ? [1] : []
    content {
      acm_certificate_arn      = aws_acm_certificate_validation.site[0].certificate_arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = "TLSv1.2_2021"
    }
  }
}
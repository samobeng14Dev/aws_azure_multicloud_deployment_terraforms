# AWS S3 hosts the primary static website used by CloudFront.
# This file creates the public website bucket, enables website hosting, and uploads the
# static frontend files with the correct content types for browsers to render them properly.

locals {
  # Keep the website root files explicit; assets are discovered recursively below.
  site_dir = "${path.module}/../website"

  site_files = {
    "index.html" = "text/html"
    "styles.css" = "text/css"
    "script.js"  = "application/javascript"
    "config.js"  = "application/javascript"
  }

  # Common static asset types; unknown extensions fall back to binary content.
  mime_types = {
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
    svg  = "image/svg+xml"
    webp = "image/webp"
    ico  = "image/x-icon"
  }
}

# Create the S3 bucket that hosts the static website content.
resource "aws_s3_bucket" "weather_app" {
  bucket = var.bucket_name
}

# Configure the bucket as a static website so it exposes the index document at the public endpoint.
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.weather_app.id

  index_document {
    suffix = "index.html"
  }
}

# Allow public reads required for a static website served from S3.
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.weather_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Grant anonymous visitors read access to website objects without requiring AWS credentials.
resource "aws_s3_bucket_policy" "public_read" {
  bucket     = aws_s3_bucket.weather_app.id
  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.weather_app.arn}/*"
    }]
  })
}

# Upload the main HTML, CSS, and JavaScript files with the correct MIME types.
resource "aws_s3_object" "site_files" {
  for_each     = local.site_files
  bucket       = aws_s3_bucket.weather_app.id
  key          = each.key
  source       = "${local.site_dir}/${each.key}"
  etag         = filemd5("${local.site_dir}/${each.key}")
  content_type = each.value
}

# Upload static assets under website/assets while keeping the same relative path structure.
resource "aws_s3_object" "site_assets" {
  for_each = fileset("${local.site_dir}/assets", "**")
  bucket   = aws_s3_bucket.weather_app.id
  key      = "assets/${each.value}"
  source   = "${local.site_dir}/assets/${each.value}"
  etag     = filemd5("${local.site_dir}/assets/${each.value}")

  # Derive the file extension from each path so nested assets also receive a correct MIME type.
  content_type = lookup(local.mime_types, lower(reverse(split(".", each.value))[0]), "application/octet-stream")
}
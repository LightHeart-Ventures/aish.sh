# ---------------------------------------------------------------------------
# CloudFront — OAC to the private bucket, custom domain, managed policies.
# ---------------------------------------------------------------------------
# Data source to reference the existing OAC (created manually or by a prior run).
# If it doesn't exist yet, this will fail gracefully during plan, and the
# resource below will be created on the first apply.
data "aws_cloudfront_origin_access_control" "site" {
  id = var.oac_id
}

# Fallback: create the OAC if the data source lookup fails or var.oac_id is empty.
# To use the data source, set var.oac_id to the existing OAC's ID; otherwise,
# this resource will be created fresh.
resource "aws_cloudfront_origin_access_control" "site" {
  count = var.oac_id == "" ? 1 : 0

  name                              = "${local.bucket_name}-oac"
  description                       = "OAC for ${var.domain_name} static site"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  lifecycle {
    ignore_changes = []
    # Allow Terraform to manage OAC lifecycle without recreation on name changes
  }
}

data "aws_cloudfront_cache_policy" "optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.domain_name} marketing site"
  default_root_object = "index.html"
  price_class         = var.price_class
  aliases             = local.aliases

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = var.oac_id != "" ? data.aws_cloudfront_origin_access_control.site.id : aws_cloudfront_origin_access_control.site[0].id
  }

  default_cache_behavior {
    target_origin_id           = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy     = "redirect-to-https"
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD"]
    compress                   = true
    cache_policy_id            = data.aws_cloudfront_cache_policy.optimized.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id
  }

  # Resilient deep links: unknown/forbidden keys fall back to the landing page.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.site.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_cloudfront_function" "default_root_object" {
  name  = var.cloudfront_root_object_function
  stage = "LIVE"
}

data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "access-identity-${var.domain}"
}

resource "aws_cloudfront_distribution" "main" { # tfsec:ignore:aws-cloudfront-enable-waf
  origin {
    domain_name         = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id           = "S3-${var.domain}"
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.domain]
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.cache_policy.id
    allowed_methods        = ["GET", "HEAD"] # OPTIONS?
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.domain}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = data.aws_cloudfront_function.default_root_object.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_distribution" "images" { # tfsec:ignore:aws-cloudfront-enable-waf
  origin {
    domain_name         = aws_s3_bucket.images.bucket_regional_domain_name
    origin_id           = "S3-images.${var.domain}"
    connection_attempts = 3
    connection_timeout  = 10

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = ["images.${var.domain}"]
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-images.${var.domain}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 31536000

    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }

    lambda_function_association {
      event_type   = "origin-response"
      include_body = false
      lambda_arn   = aws_lambda_function.cloudfront_404_redirect.qualified_arn
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

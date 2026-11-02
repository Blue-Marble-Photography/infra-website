# CloudFront stack for the site and images: viewer-request functions, cache and response
# headers policies, OAC, both distributions, and the 404_redirect Lambda@Edge.
# Instantiated once per AWS account during the account migration; the provider passed in decides
# the account. Lambda@Edge requires us-east-1.

resource "aws_cloudfront_function" "site_viewer_request" {
  name    = "${replace(var.domain, ".", "-")}-site-viewer-request"
  comment = "Reject AI crawlers; serve index.html for directory URLs"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = templatefile("${path.module}/functions/viewer-request.js", {
    ai_agents_pattern = var.ai_agents_pattern
    rewrite_index     = true
  })
}

resource "aws_cloudfront_function" "images_viewer_request" {
  name    = "${replace(var.domain, ".", "-")}-images-viewer-request"
  comment = "Reject AI crawlers"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = templatefile("${path.module}/functions/viewer-request.js", {
    ai_agents_pattern = var.ai_agents_pattern
    rewrite_index     = false
  })
}

data "aws_cloudfront_cache_policy" "cache_policy" {
  name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "s3-${var.domain}"
  description                       = "S3 origins for ${var.domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# TTLs match the old forwarded_values settings. default_ttl must stay 0: the origin-response
# Lambda@Edge turns S3 404s into redirects to the resize API, and those must not be cached.
resource "aws_cloudfront_cache_policy" "images" {
  name        = "images-${replace(var.domain, ".", "-")}"
  comment     = "No caching without Cache-Control; redirects from the resize Lambda stay uncached"
  min_ttl     = 0
  default_ttl = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

#trivy:ignore:AVD-AWS-0010 # No logging required
#trivy:ignore:AVD-AWS-0011 # No WAF required
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = var.site_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-${var.domain}"
    connection_attempts      = 3
    connection_timeout       = 10
  }
  enabled             = true
  is_ipv6_enabled     = true
  wait_for_deployment = var.wait_for_deployment
  aliases             = local.aliases_enabled ? [var.domain] : []
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }

  default_cache_behavior {
    cache_policy_id            = data.aws_cloudfront_cache_policy.cache_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    allowed_methods            = ["GET", "HEAD"] # OPTIONS?
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${var.domain}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.site_viewer_request.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = var.certificate_arn == null ? null : "sni-only"
    minimum_protocol_version       = var.certificate_arn == null ? "TLSv1" : "TLSv1.2_2021"
  }
}

# Same security headers as Managed-SecurityHeadersPolicy, plus AI opt-out signals:
# X-Robots-Tag noai/noimageai and the W3C TDMRep text-and-data-mining reservation.
resource "aws_cloudfront_response_headers_policy" "site" {
  name    = "site-${replace(var.domain, ".", "-")}"
  comment = "Managed security headers plus AI training opt-out"

  custom_headers_config {
    items {
      header   = "X-Robots-Tag"
      value    = "noai, noimageai"
      override = true
    }

    items {
      header   = "tdm-reservation"
      value    = "1"
      override = true
    }

    items {
      header   = "tdm-policy"
      value    = "https://${var.domain}/license/"
      override = true
    }
  }

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = false
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = false
    }
  }
}

# Originals are offered as downloads, but the attachment header was only set on some
# uploads. Add it at the edge for every original, alongside the same security headers
# as Managed-SecurityHeadersPolicy (a behavior takes only one response headers policy).
resource "aws_cloudfront_response_headers_policy" "originals_download" {
  name    = "originals-download-${replace(var.domain, ".", "-")}"
  comment = "Managed security headers, AI opt-out, and Content-Disposition: attachment"

  custom_headers_config {
    items {
      header   = "Content-Disposition"
      value    = "attachment"
      override = true
    }

    items {
      header   = "X-Robots-Tag"
      value    = "noai, noimageai"
      override = true
    }

    items {
      header   = "tdm-reservation"
      value    = "1"
      override = true
    }

    items {
      header   = "tdm-policy"
      value    = "https://${var.domain}/license/"
      override = true
    }
  }

  security_headers_config {
    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "SAMEORIGIN"
      override     = false
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }

    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = false
    }

    xss_protection {
      protection = true
      mode_block = true
      override   = false
    }
  }
}

#trivy:ignore:AVD-AWS-0010 # No logging required
#trivy:ignore:AVD-AWS-0011 # No WAF required
resource "aws_cloudfront_distribution" "images" {
  # Resized copies live under generated/ (written by the resize Lambda); viewer URLs stay at the root.
  origin {
    domain_name              = var.images_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-images.${var.domain}"
    origin_path              = "/generated"
    connection_attempts      = 3
    connection_timeout       = 10
  }

  # Bucket root: originals/, robots.txt, .well-known/.
  origin {
    domain_name              = var.images_bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-images-root.${var.domain}"
    connection_attempts      = 3
    connection_timeout       = 10
  }
  enabled             = true
  is_ipv6_enabled     = true
  wait_for_deployment = var.wait_for_deployment
  aliases             = local.aliases_enabled ? ["images.${var.domain}"] : []
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  default_cache_behavior {
    cache_policy_id            = aws_cloudfront_cache_policy.images.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-images.${var.domain}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.images_viewer_request.arn
    }

    lambda_function_association {
      event_type   = "origin-response"
      include_body = false
      lambda_arn   = aws_lambda_function.cloudfront_404_redirect.qualified_arn
    }
  }

  # Full-resolution originals: always download. No resize redirect; originals have no sizes.
  ordered_cache_behavior {
    path_pattern               = "originals/*"
    cache_policy_id            = aws_cloudfront_cache_policy.images.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.originals_download.id
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-images-root.${var.domain}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.images_viewer_request.arn
    }
  }

  # Crawler and TDMRep opt-out files at the bucket root (tofu objects); a miss is a plain 404, not a resize.
  ordered_cache_behavior {
    path_pattern               = "robots.txt"
    cache_policy_id            = aws_cloudfront_cache_policy.images.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-images-root.${var.domain}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.images_viewer_request.arn
    }
  }

  ordered_cache_behavior {
    path_pattern               = ".well-known/*"
    cache_policy_id            = aws_cloudfront_cache_policy.images.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site.id
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-images-root.${var.domain}"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.images_viewer_request.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = var.certificate_arn == null
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = var.certificate_arn == null ? null : "sni-only"
    minimum_protocol_version       = var.certificate_arn == null ? "TLSv1" : "TLSv1.2_2021"
  }
}

data "archive_file" "cloudfront_404_redirect_lambda_zip_file" {
  type        = "zip"
  output_path = var.lambda_zip_path

  source {
    content  = file("${path.module}/lambdas/404_redirect/main.py")
    filename = "main.py"
  }
}

resource "aws_lambda_function" "cloudfront_404_redirect" {
  function_name = "cloudfront-404-apigateway-redirect"
  role          = aws_iam_role.lambda_at_edge.arn
  handler       = "main.lambda_handler"

  filename         = data.archive_file.cloudfront_404_redirect_lambda_zip_file.output_path
  source_code_hash = data.archive_file.cloudfront_404_redirect_lambda_zip_file.output_base64sha256

  runtime = "python3.14"
  timeout = "10"
  publish = true
}

resource "aws_iam_role" "lambda_at_edge" {
  name               = "${var.domain}-lambda-edge"
  assume_role_policy = file("${path.module}/templates/iam-lambda-edge-trust.json")
}

resource "aws_iam_role_policy" "lambda_at_edge_logs" {
  name   = "${var.domain}-logs"
  role   = aws_iam_role.lambda_at_edge.id
  policy = file("${path.module}/templates/iam-logs-policy.json")
}

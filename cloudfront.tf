locals {
  # AI crawlers and AI search/assistant agents rejected at the edge (case-insensitive
  # substring match). Narrower than robots.txt: nothing that powers link previews
  # (facebookexternalhit) or ordinary search.
  ai_agents = [
    "GPTBot", "ChatGPT-User", "ChatGPT Agent", "OAI-SearchBot",
    "ClaudeBot", "Claude-User", "Claude-SearchBot", "Claude-Web", "anthropic-ai",
    "CCBot", "Bytespider", "PerplexityBot", "Perplexity-User",
    "meta-externalagent", "meta-externalfetcher", "FacebookBot", "Amazonbot",
    "cohere-ai", "cohere-training-data-crawler", "Diffbot", "ImagesiftBot", "img2dataset",
    "LAIONDownloader", "laion-huggingface-processor", "Timpibot", "omgili", "Webzio-Extended",
    "AI2Bot", "PanguBot", "DeepSeekBot", "MistralAI", "QwenBot", "TikTokSpider",
    "DuckAssistBot", "CloudVertexBot", "GrokBot", "Kangaroo Bot", "YouBot", "iaskspider",
    "Brightbot", "imageSpider", "FirecrawlAgent", "Crawl4AI", "ExaBot", "TavilyBot",
    "KimiBot", "DoubaoBot", "ERNIEBot", "YiyanBot", "Manus-User", "Gemini-Deep-Research",
    "GoogleAgent", "NovaAct", "bedrockbot", "AzureAI-SearchBot", "ChatGLM-Spider",
    "Andibot", "PhindBot", "LinerBot", "ShapBot",
  ]
  # Names are letters, digits, hyphens, and spaces only, so no regex escaping is needed.
  ai_agents_pattern = join("|", local.ai_agents)
}

resource "aws_cloudfront_function" "site_viewer_request" {
  name    = "${replace(var.domain, ".", "-")}-site-viewer-request"
  comment = "Reject AI crawlers; serve index.html for directory URLs"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = templatefile("functions/viewer-request.js", {
    ai_agents_pattern = local.ai_agents_pattern
    rewrite_index     = true
  })
}

resource "aws_cloudfront_function" "images_viewer_request" {
  name    = "${replace(var.domain, ".", "-")}-images-viewer-request"
  comment = "Reject AI crawlers"
  runtime = "cloudfront-js-2.0"
  publish = true
  code = templatefile("functions/viewer-request.js", {
    ai_agents_pattern = local.ai_agents_pattern
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
    domain_name              = aws_s3_bucket.main.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-${var.domain}"
    connection_attempts      = 3
    connection_timeout       = 10
  }
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.domain]
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
    acm_certificate_arn      = aws_acm_certificate_validation.validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
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
  origin {
    domain_name              = aws_s3_bucket.images.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-images.${var.domain}"
    connection_attempts      = 3
    connection_timeout       = 10
  }
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = ["images.${var.domain}"]
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
    target_origin_id           = "S3-images.${var.domain}"
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
    acm_certificate_arn      = aws_acm_certificate_validation.validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

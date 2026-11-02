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

# CloudFront stack in the old account (530167849052), serving production until the phase 4 cutover.
module "cdn_legacy" {
  source = "./modules/cdn"

  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.main.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images_site.bucket_regional_domain_name
  certificate_arn                    = aws_acm_certificate_validation.validation.certificate_arn
  lambda_zip_path                    = "/tmp/lambda-404-redirect-${var.domain}.zip"
  ai_agents_pattern                  = local.ai_agents_pattern
}

moved {
  from = aws_cloudfront_function.site_viewer_request
  to   = module.cdn_legacy.aws_cloudfront_function.site_viewer_request
}

moved {
  from = aws_cloudfront_function.images_viewer_request
  to   = module.cdn_legacy.aws_cloudfront_function.images_viewer_request
}

moved {
  from = aws_cloudfront_origin_access_control.s3
  to   = module.cdn_legacy.aws_cloudfront_origin_access_control.s3
}

moved {
  from = aws_cloudfront_cache_policy.images
  to   = module.cdn_legacy.aws_cloudfront_cache_policy.images
}

moved {
  from = aws_cloudfront_distribution.main
  to   = module.cdn_legacy.aws_cloudfront_distribution.main
}

moved {
  from = aws_cloudfront_distribution.images
  to   = module.cdn_legacy.aws_cloudfront_distribution.images
}

moved {
  from = aws_cloudfront_response_headers_policy.site
  to   = module.cdn_legacy.aws_cloudfront_response_headers_policy.site
}

moved {
  from = aws_cloudfront_response_headers_policy.originals_download
  to   = module.cdn_legacy.aws_cloudfront_response_headers_policy.originals_download
}

moved {
  from = aws_lambda_function.cloudfront_404_redirect
  to   = module.cdn_legacy.aws_lambda_function.cloudfront_404_redirect
}

moved {
  from = aws_iam_role.lambda_at_edge
  to   = module.cdn_legacy.aws_iam_role.lambda_at_edge
}

moved {
  from = aws_iam_role_policy.lambda_at_edge_logs
  to   = module.cdn_legacy.aws_iam_role_policy.lambda_at_edge_logs
}

# CloudFront stack in the site account (508360653481). No certificate yet: it answers only on its
# *.cloudfront.net domains until the phase 4 cutover moves the aliases here.
module "cdn_site" {
  source = "./modules/cdn"
  providers = {
    aws = aws.site
  }

  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.site.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images_site.bucket_regional_domain_name
  certificate_arn                    = null
  lambda_zip_path                    = "${path.module}/build/lambda-404-redirect-site.zip"
  ai_agents_pattern                  = local.ai_agents_pattern
}

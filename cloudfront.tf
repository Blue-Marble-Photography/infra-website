# CloudFront stack in the old account (530167849052). Its aliases moved to cdn_site in the phase 4b
# cutover; it stays intact as the rollback until phase 5 deletes it.
module "cdn_legacy" {
  source = "./modules/cdn"

  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.main.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images_site.bucket_regional_domain_name
  certificate_arn                    = aws_acm_certificate_validation.validation.certificate_arn
  aliases_enabled                    = false
  wait_for_deployment                = false
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

# CloudFront stack in the site account (508360653481), serving bluemarble.photography and images.*
# since the phase 4b cutover.
module "cdn_site" {
  source = "./modules/cdn"
  providers = {
    aws = aws.site
  }

  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.site.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images_site.bucket_regional_domain_name
  certificate_arn                    = aws_acm_certificate_validation.site.certificate_arn
  lambda_zip_path                    = "${path.module}/build/lambda-404-redirect-site.zip"
  ai_agents_pattern                  = local.ai_agents_pattern
}

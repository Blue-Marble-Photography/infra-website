# CloudFront stack: site and images distributions, viewer-request functions, policies, OAC, and
# the 404_redirect Lambda@Edge.
module "cdn" {
  source                             = "./modules/cdn"
  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.main.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images.bucket_regional_domain_name
  certificate_arn                    = aws_acm_certificate_validation.main.certificate_arn
  lambda_zip_path                    = "${path.module}/build/lambda-404-redirect-site.zip"
  ai_agents_pattern                  = local.ai_agents_pattern
}

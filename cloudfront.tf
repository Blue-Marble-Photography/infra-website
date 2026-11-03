# Old-account Lambda@Edge and its role: AWS deletes a Lambda@Edge function only after its edge
# replicas clear (hours after its distribution is gone), so phase 5a drops them from state and they
# are deleted by CLI afterwards (phase5-cleanup.md).
removed {
  from = module.cdn_legacy.aws_lambda_function.cloudfront_404_redirect

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.cdn_legacy.aws_iam_role_policy.lambda_at_edge_logs

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.cdn_legacy.aws_iam_role.lambda_at_edge

  lifecycle {
    destroy = false
  }
}

moved {
  from = module.cdn_site
  to   = module.cdn
}

# CloudFront stack: site and images distributions, viewer-request functions, policies, OAC, and
# the 404_redirect Lambda@Edge.
module "cdn" {
  source = "./modules/cdn"
  providers = {
    aws = aws.site
  }

  domain                             = var.domain
  site_bucket_regional_domain_name   = aws_s3_bucket.site.bucket_regional_domain_name
  images_bucket_regional_domain_name = aws_s3_bucket.images_site.bucket_regional_domain_name
  certificate_arn                    = aws_acm_certificate_validation.main.certificate_arn
  lambda_zip_path                    = "${path.module}/build/lambda-404-redirect-site.zip"
  ai_agents_pattern                  = local.ai_agents_pattern
}

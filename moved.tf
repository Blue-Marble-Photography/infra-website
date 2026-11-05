# Phase 5b renames (phase5-cleanup.md); delete once applied.

moved {
  from = aws_route53_zone.site
  to   = aws_route53_zone.main
}

moved {
  from = aws_route53domains_registered_domain.domain
  to   = aws_route53domains_registered_domain.main
}

moved {
  from = aws_route53_record.site_cert_validation
  to   = aws_route53_record.acm_cert_validation
}

moved {
  from = aws_s3_bucket.site
  to   = aws_s3_bucket.main
}

moved {
  from = aws_s3_bucket_ownership_controls.site
  to   = aws_s3_bucket_ownership_controls.main
}

moved {
  from = aws_s3_bucket_public_access_block.site
  to   = aws_s3_bucket_public_access_block.main
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.site
  to   = aws_s3_bucket_server_side_encryption_configuration.main
}

moved {
  from = aws_s3_bucket_policy.site
  to   = aws_s3_bucket_policy.main
}

moved {
  from = aws_ssm_parameter.site_website_bucket_name
  to   = aws_ssm_parameter.website_bucket_name
}

moved {
  from = aws_ssm_parameter.site_website_distribution
  to   = aws_ssm_parameter.website_distribution
}

moved {
  from = aws_iam_role_policy.site_website_deploy
  to   = aws_iam_role_policy.website_deploy
}

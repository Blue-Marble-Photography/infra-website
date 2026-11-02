# Read by the website repo's deploy workflow.
resource "aws_ssm_parameter" "website_bucket_name" {
  name  = "/website/bucket-name"
  type  = "String"
  value = aws_s3_bucket.main.id
}

resource "aws_ssm_parameter" "website_distribution" {
  name  = "/website/cloudfront-distribution"
  type  = "String"
  value = module.cdn_legacy.main_distribution_id
}

# Site-account copies, read once the website workflow deploys straight into 508360653481.
resource "aws_ssm_parameter" "site_website_bucket_name" {
  provider = aws.site
  name     = "/website/bucket-name"
  type     = "String"
  value    = aws_s3_bucket.site.id
}

resource "aws_ssm_parameter" "site_website_distribution" {
  provider = aws.site
  name     = "/website/cloudfront-distribution"
  type     = "String"
  value    = module.cdn_site.main_distribution_id
}

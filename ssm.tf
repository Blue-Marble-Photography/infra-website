# Read by the website repo's deploy workflow.
resource "aws_ssm_parameter" "website_bucket_name" {
  provider = aws.site
  name     = "/website/bucket-name"
  type     = "String"
  value    = aws_s3_bucket.main.id
}

resource "aws_ssm_parameter" "website_distribution" {
  provider = aws.site
  name     = "/website/cloudfront-distribution"
  type     = "String"
  value    = module.cdn.main_distribution_id
}

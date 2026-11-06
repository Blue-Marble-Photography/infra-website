# Read by the website repo's deploy workflow.
resource "aws_ssm_parameter" "website_bucket_name" {
  name  = "/website/bucket-name"
  type  = "String"
  value = aws_s3_bucket.site.id
}

resource "aws_ssm_parameter" "website_distribution" {
  name  = "/website/cloudfront-distribution"
  type  = "String"
  value = module.cdn.site_distribution_id
}

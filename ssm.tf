# Read by the website repo's deploy workflow.
resource "aws_ssm_parameter" "website_bucket_name" {
  name  = "/website/bucket-name"
  type  = "String"
  value = aws_s3_bucket.main.id
}

resource "aws_ssm_parameter" "website_distribution" {
  name  = "/website/cloudfront-distribution"
  type  = "String"
  value = aws_cloudfront_distribution.main.id
}

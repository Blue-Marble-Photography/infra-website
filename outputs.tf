output "site_bucket_name" {
  description = "S3 bucket the site deploys to (CI variable S3_BUCKET_NAME)"
  value       = aws_s3_bucket.main.id
}

output "site_distribution_id" {
  description = "CloudFront distribution for the site (CI variable CLOUDFRONT_DISTRIBUTION_ID)"
  value       = aws_cloudfront_distribution.main.id
}

output "images_bucket_name" {
  description = "S3 bucket holding original and resized images"
  value       = aws_s3_bucket.images.id
}

output "images_distribution_id" {
  description = "CloudFront distribution for images"
  value       = aws_cloudfront_distribution.images.id
}

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

output "bluemarble_infra_role_arn" {
  description = "Role the aws provider assumes from the state account"
  value       = aws_iam_role.bluemarble_infra.arn
}

output "website_deploy_role_arn" {
  description = "Role the website deploy workflow chains into"
  value       = aws_iam_role.website_deploy.arn
}

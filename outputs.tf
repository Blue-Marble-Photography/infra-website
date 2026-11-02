output "bluemarble_infra_role_arn" {
  description = "Role the aws provider assumes from the state account"
  value       = aws_iam_role.bluemarble_infra.arn
}

output "images_bucket_name" {
  description = "S3 bucket holding original and resized images"
  value       = aws_s3_bucket.images.id
}

output "images_distribution_id" {
  description = "CloudFront distribution for images"
  value       = module.cdn_legacy.images_distribution_id
}

output "images_site_bucket_name" {
  description = "Images bucket in the site account (508360653481), replacing images_bucket_name"
  value       = aws_s3_bucket.images_site.id
}

output "site_bucket_name" {
  description = "S3 bucket the site deploys to (CI variable S3_BUCKET_NAME)"
  value       = aws_s3_bucket.main.id
}

output "site_distribution_id" {
  description = "CloudFront distribution for the site (CI variable CLOUDFRONT_DISTRIBUTION_ID)"
  value       = module.cdn_legacy.main_distribution_id
}

output "site_images_distribution_domain" {
  description = "Site-account images distribution (*.cloudfront.net) for testing before the cutover"
  value       = module.cdn_site.images_distribution_domain_name
}

output "site_main_distribution_domain" {
  description = "Site-account site distribution (*.cloudfront.net) for testing before the cutover"
  value       = module.cdn_site.main_distribution_domain_name
}

output "site_zone_name_servers" {
  description = "Name servers of the site-account hosted zone"
  value       = aws_route53_zone.site.name_servers
}

output "website_deploy_role_arn" {
  description = "Role the website deploy workflow chains into"
  value       = aws_iam_role.website_deploy.arn
}

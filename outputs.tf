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
  value       = module.cdn.images_distribution_id
}

output "images_site_bucket_name" {
  description = "Images bucket in the site account (508360653481), replacing images_bucket_name"
  value       = aws_s3_bucket.images_site.id
}

output "site_bucket_name" {
  description = "S3 bucket the website deploys to"
  value       = aws_s3_bucket.main.id
}

output "site_distribution_id" {
  description = "CloudFront distribution for the site"
  value       = module.cdn.main_distribution_id
}

output "zone_name_servers" {
  description = "Name servers of the bluemarble.photography hosted zone"
  value       = aws_route53_zone.main.name_servers
}

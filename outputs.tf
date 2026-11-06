output "images_bucket_name" {
  description = "S3 bucket holding original and resized images"
  value       = aws_s3_bucket.images.id
}

output "images_distribution_id" {
  description = "CloudFront distribution for images"
  value       = module.cdn.images_distribution_id
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

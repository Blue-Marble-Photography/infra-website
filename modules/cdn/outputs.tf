output "images_distribution_arn" {
  description = "Images distribution ARN"
  value       = aws_cloudfront_distribution.images.arn
}

output "images_distribution_domain_name" {
  description = "Images distribution *.cloudfront.net domain"
  value       = aws_cloudfront_distribution.images.domain_name
}

output "images_distribution_hosted_zone_id" {
  description = "Hosted zone ID for Route 53 alias records to the images distribution"
  value       = aws_cloudfront_distribution.images.hosted_zone_id
}

output "images_distribution_id" {
  description = "Images distribution ID"
  value       = aws_cloudfront_distribution.images.id
}

output "site_distribution_arn" {
  description = "Site distribution ARN"
  value       = aws_cloudfront_distribution.site.arn
}

output "site_distribution_domain_name" {
  description = "Site distribution *.cloudfront.net domain"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "site_distribution_hosted_zone_id" {
  description = "Hosted zone ID for Route 53 alias records to the site distribution"
  value       = aws_cloudfront_distribution.site.hosted_zone_id
}

output "site_distribution_id" {
  description = "Site distribution ID"
  value       = aws_cloudfront_distribution.site.id
}

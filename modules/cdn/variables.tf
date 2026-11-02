variable "domain" {
  description = "Site domain (bluemarble.photography)"
  type        = string
}

variable "site_bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket holding the built website"
  type        = string
}

variable "images_bucket_regional_domain_name" {
  description = "Regional domain name of the images bucket (originals/, generated/, robots.txt, .well-known/)"
  type        = string
}

variable "certificate_arn" {
  description = "Validated ACM certificate for the aliases; null serves the default *.cloudfront.net certificate and no aliases"
  type        = string
  default     = null
}

variable "lambda_zip_path" {
  description = "Where to build the 404_redirect zip; under build/ so tofu-cd.yml carries it from plan to apply"
  type        = string
}

variable "ai_agents_pattern" {
  description = "Regex alternation of AI crawler user agents rejected at the edge"
  type        = string
}

variable "aliases_enabled" {
  description = "Attach the domain aliases (needs certificate_arn); false lets the certificate attach before the aliases move here"
  type        = bool
  default     = true
}

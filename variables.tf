variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "personal"
}

variable "tags" {
  type = map(string)
  default = {
    Project = "bluemarble.photography"
  }
}

variable "domain" {
  description = "Domain"
  type        = string
  default     = "bluemarble.photography"
}

variable "domain_aliases" {
  description = "Website domain aliases"
  type        = list(any)
  default     = ["api.bluemarble.photography", "images.bluemarble.photography"]
}

variable "mx_records" {
  description = "MX DNS records"
  type        = string
  default     = "10 inbound-smtp.us-east-1.amazonaws.com"
}

variable "site_verification" {
  description = "Site verification records"
  type        = list(any)
  default = [
    "google-site-verification=iw4ChOj0kx3skuukypp2k8u9-orl5uXGS7_gHY2-aFA",
    "facebook-domain-verification=f83a6ftg8de0aj79jkvxhv8rcplvy7"
  ]
}

variable "cloudfront_root_object_function" {
  description = "CloudFront function for default root object"
  type        = string
  default     = "default-root-object"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "resources_account_id" {
  description = "Account holding the site's resources until the account migration (provider assumes bluemarble-infra here)"
  type        = string
  default     = "530167849052"
}

variable "site_account_id" {
  description = "Sub-account granted read access to the images bucket for the planned account migration"
  type        = string
  default     = "508360653481"
}

variable "tags" {
  description = "Default tags applied to every resource"
  type        = map(string)
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
  type        = list(string)
  default     = ["api.bluemarble.photography", "images.bluemarble.photography"]
}

variable "mx_records" {
  description = "MX DNS records"
  type        = string
  default     = "10 inbound-smtp.us-east-1.amazonaws.com"
}

variable "site_verification" {
  description = "Site verification records"
  type        = list(string)
  default = [
    "google-site-verification=iw4ChOj0kx3skuukypp2k8u9-orl5uXGS7_gHY2-aFA",
    "facebook-domain-verification=f83a6ftg8de0aj79jkvxhv8rcplvy7"
  ]
}

variable "gitlab_project_path" {
  description = "GitLab project allowed to assume the CI role (OIDC sub claim)"
  type        = string
  default     = "joseph.gruber/bluemarble.photography"
}

variable "resize_stack_name" {
  description = "CloudFormation stack of the resize Lambda (lambdas/resize-images/samconfig.toml)"
  type        = string
  default     = "resize-images-app"
}

variable "sam_artifacts_bucket" {
  description = "SAM-managed bucket holding resize Lambda deploy artifacts (samconfig.toml s3_bucket)"
  type        = string
  default     = "aws-sam-cli-managed-default-samclisourcebucket-jgpso52uwphy"
}

variable "state_account_id" {
  description = "Site's own account: holds the OpenTofu state and the GitHub Actions roles (infra-aws-base)"
  type        = string
  default     = "508360653481"
}

variable "apex_txt_records" {
  description = "Apex TXT records: site verifications and SPF"
  type        = list(string)
  default = [
    "google-site-verification=iw4ChOj0kx3skuukypp2k8u9-orl5uXGS7_gHY2-aFA",
    "facebook-domain-verification=f83a6ftg8de0aj79jkvxhv8rcplvy7",
    "protonmail-verification=b58d71fb285e75888a242966d213c442c8f96572",
    "v=spf1 include:_spf.protonmail.ch ~all",
  ]
}

variable "aws_region" {
  description = "AWS region for every resource; must be us-east-1 for CloudFront certificates and Lambda@Edge"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "CloudFront certificates and Lambda@Edge require us-east-1."
  }
}

variable "default_tags" {
  description = "Key/value pairs for default tags to add to resources"
  type        = map(string)
  default = {
    ManagedBy = "OpenTofu"
    Project   = "bluemarble.photography"
  }
}

variable "domain" {
  description = "Apex domain of the site; images.* and api.* hang off it"
  type        = string
  default     = "bluemarble.photography"
}

variable "mx_records" {
  description = "MX DNS records (Proton Mail)"
  type        = list(string)
  default     = ["10 mail.protonmail.ch", "20 mailsec.protonmail.ch"]
}

variable "proton_dkim" {
  description = "Proton Mail DKIM CNAMEs: selector => target"
  type        = map(string)
  default = {
    protonmail  = "protonmail.domainkey.dsnmqp5ebgvgs3c5qn7fuswt4eprnwv3qldi3tlwgjmpwmg4wbria.domains.proton.ch."
    protonmail2 = "protonmail2.domainkey.dsnmqp5ebgvgs3c5qn7fuswt4eprnwv3qldi3tlwgjmpwmg4wbria.domains.proton.ch."
    protonmail3 = "protonmail3.domainkey.dsnmqp5ebgvgs3c5qn7fuswt4eprnwv3qldi3tlwgjmpwmg4wbria.domains.proton.ch."
  }
}

variable "site_account_id" {
  description = "Site account (508360653481): holds every resource, the state, and the CI roles"
  type        = string
  default     = "508360653481"
}

variable "website_role_name" {
  description = "Website deploy role created by infra-aws-base; iam.tf attaches the deploy policy to it"
  type        = string
  default     = "github-actions-website"
}

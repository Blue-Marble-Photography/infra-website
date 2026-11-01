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
  description = "MX DNS records (Proton Mail)"
  type        = list(string)
  default     = ["10 mail.protonmail.ch", "20 mailsec.protonmail.ch"]
}

variable "site_verification" {
  description = "Apex TXT records: site verifications and SPF"
  type        = list(string)
  default = [
    "google-site-verification=iw4ChOj0kx3skuukypp2k8u9-orl5uXGS7_gHY2-aFA",
    "facebook-domain-verification=f83a6ftg8de0aj79jkvxhv8rcplvy7",
    "protonmail-verification=b58d71fb285e75888a242966d213c442c8f96572",
    "v=spf1 include:_spf.protonmail.ch ~all"
  ]
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

variable "state_account_id" {
  description = "Site's own account: holds the OpenTofu state and the GitHub Actions roles (infra-aws-base)"
  type        = string
  default     = "508360653481"
}

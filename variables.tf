variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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

variable "tags" {
  description = "Default tags applied to every resource"
  type        = map(string)
  default = {
    Project = "bluemarble.photography"
  }
}

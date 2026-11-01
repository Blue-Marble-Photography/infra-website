# Domain registration (Route 53 Domains) in the site account; transferred from 530167849052 on
# 2026-11-01. Name servers point at the hosted zone that serves the domain.

import {
  to = aws_route53domains_registered_domain.domain
  id = var.domain
}

resource "aws_route53domains_registered_domain" "domain" {
  provider    = aws.site
  domain_name = var.domain

  auto_renew    = true
  transfer_lock = true

  admin_privacy      = true
  registrant_privacy = true
  tech_privacy       = true
  billing_privacy    = true

  name_server {
    name = "ns-1013.awsdns-62.net"
  }
  name_server {
    name = "ns-1364.awsdns-42.org"
  }
  name_server {
    name = "ns-1769.awsdns-29.co.uk"
  }
  name_server {
    name = "ns-455.awsdns-56.com"
  }
}

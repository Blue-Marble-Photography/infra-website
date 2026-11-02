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

  # The site-account zone (dns-site.tf). DNSSEC was dropped on 2026-11-01 before the move.
  dynamic "name_server" {
    for_each = aws_route53_zone.site.name_servers
    content {
      name = name_server.value
    }
  }
}

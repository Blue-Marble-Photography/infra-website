# bluemarble.photography hosted zone (site account, 508360653481). No DNSSEC: dropped on
# 2026-11-01 when the zone moved accounts.

resource "aws_route53_zone" "main" {
  name          = var.domain
  comment       = "bluemarble.photography (site account)"
  force_destroy = false
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = module.cdn.main_distribution_domain_name
    zone_id                = module.cdn.main_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "root_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "AAAA"

  alias {
    name                   = module.cdn.main_distribution_domain_name
    zone_id                = module.cdn.main_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "images" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "images.${var.domain}"
  type    = "A"

  alias {
    name                   = module.cdn.images_distribution_domain_name
    zone_id                = module.cdn.images_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "images_ipv6" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "images.${var.domain}"
  type    = "AAAA"

  alias {
    name                   = module.cdn.images_distribution_domain_name
    zone_id                = module.cdn.images_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "MX"
  ttl     = "300"
  records = var.mx_records
}

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = "300"
  records = var.site_verification
}

resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = "300"
  records = ["v=DMARC1; p=quarantine"]
}

resource "aws_route53_record" "proton_dkim" {
  for_each = var.proton_dkim
  zone_id  = aws_route53_zone.main.zone_id
  name     = "${each.key}._domainkey.${var.domain}"
  type     = "CNAME"
  ttl      = "300"
  records  = [each.value]
}

# Hosted zone in the site account (account-migration.md, phase 3). Mirrors every record in the
# old zone (dns.tf, acm.tf, api.tf) until the registration's name servers switch here; then the
# old zone and its records go away. No DNSSEC.

resource "aws_route53_zone" "site" {
  provider      = aws.site
  name          = var.domain
  comment       = "bluemarble.photography (site account)"
  force_destroy = false
}

resource "aws_route53_record" "site_root" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = var.domain
  type     = "A"

  alias {
    name                   = module.cdn_legacy.main_distribution_domain_name
    zone_id                = module.cdn_legacy.main_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_root_ipv6" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = var.domain
  type     = "AAAA"

  alias {
    name                   = module.cdn_legacy.main_distribution_domain_name
    zone_id                = module.cdn_legacy.main_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_images" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = "images.${var.domain}"
  type     = "A"

  alias {
    name                   = module.cdn_legacy.images_distribution_domain_name
    zone_id                = module.cdn_legacy.images_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_images_ipv6" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = "images.${var.domain}"
  type     = "AAAA"

  alias {
    name                   = module.cdn_legacy.images_distribution_domain_name
    zone_id                = module.cdn_legacy.images_distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_api" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = "api.${var.domain}"
  type     = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api_site.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_site.regional_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "site_mx" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = var.domain
  type     = "MX"
  ttl      = "300"
  records  = var.mx_records
}

resource "aws_route53_record" "site_txt" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = var.domain
  type     = "TXT"
  ttl      = "300"
  records  = var.site_verification
}

resource "aws_route53_record" "site_dmarc" {
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = "_dmarc.${var.domain}"
  type     = "TXT"
  ttl      = "300"
  records  = ["v=DMARC1; p=quarantine"]
}

resource "aws_route53_record" "site_proton_dkim" {
  for_each = var.proton_dkim
  provider = aws.site
  zone_id  = aws_route53_zone.site.zone_id
  name     = "${each.key}._domainkey.${var.domain}"
  type     = "CNAME"
  ttl      = "300"
  records  = [each.value]
}

# Keeps the old account's certificate renewable until phase 5 replaces it.
resource "aws_route53_record" "site_acm_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  provider        = aws.site
  zone_id         = aws_route53_zone.site.zone_id
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

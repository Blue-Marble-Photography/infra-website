resource "aws_route53_zone" "zone" {
  name          = var.domain
  comment       = ""
  force_destroy = false
}

resource "aws_route53_record" "nameservers" {
  zone_id         = aws_route53_zone.zone.zone_id
  name            = var.domain
  type            = "NS"
  ttl             = 172800
  allow_overwrite = true

  records = [
    "${aws_route53_zone.zone.name_servers[0]}.",
    "${aws_route53_zone.zone.name_servers[1]}.",
    "${aws_route53_zone.zone.name_servers[2]}.",
    "${aws_route53_zone.zone.name_servers[3]}."
  ]
}

resource "aws_route53_record" "soa" {
  zone_id         = aws_route53_zone.zone.zone_id
  name            = var.domain
  type            = "SOA"
  ttl             = 900
  allow_overwrite = true

  records = ["${aws_route53_zone.zone.name_servers[2]}. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"]
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "MX"
  ttl     = "300"
  records = [var.mx_records]
}

resource "aws_route53_record" "txt" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = "300"
  records = var.site_verification
}

resource "aws_route53_record" "images" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "images.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.images.domain_name
    zone_id                = aws_cloudfront_distribution.images.hosted_zone_id
    evaluate_target_health = false
  }
}

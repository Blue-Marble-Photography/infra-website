# api.bluemarble.photography: custom domain for the resize API (SAM stack resize-images-app,
# lambdas/resize-images). The 404_redirect Lambda@Edge sends missing image sizes to
# https://api.bluemarble.photography/v1/resize. Created by hand in 2019; imported 2026-11-01.

# Owned by the SAM stack; looked up so the mapping follows a redeployed API.
data "aws_api_gateway_rest_api" "resize" {
  name = "resize-images-app"
}

import {
  to = aws_api_gateway_domain_name.api
  id = "api.${var.domain}"
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.${var.domain}"
  regional_certificate_arn = aws_acm_certificate_validation.validation.certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  # AWS echoes the regional certificate into the edge-only certificate_arn; clearing it is a no-op at best.
  lifecycle {
    ignore_changes = [certificate_arn]
  }
}

import {
  to = aws_api_gateway_base_path_mapping.api
  id = "api.${var.domain}/v1"
}

resource "aws_api_gateway_base_path_mapping" "api" {
  domain_name = aws_api_gateway_domain_name.api.domain_name
  api_id      = data.aws_api_gateway_rest_api.resize.id
  stage_name  = "Prod"
  base_path   = "v1"
}

import {
  to = aws_route53_record.api
  id = "Z1QWLHQSNX81E6_api.${var.domain}_A"
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.zone.zone_id
  name    = "api.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
    evaluate_target_health = false
  }
}

# Site-account copy (account-migration.md, phase 4b), mapped to the SAM stack deployed in 508360653481.
data "aws_api_gateway_rest_api" "resize_site" {
  provider = aws.site
  name     = "resize-images-app"
}

resource "aws_api_gateway_domain_name" "api_site" {
  provider                 = aws.site
  domain_name              = "api.${var.domain}"
  regional_certificate_arn = aws_acm_certificate_validation.site.certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api_site" {
  provider    = aws.site
  domain_name = aws_api_gateway_domain_name.api_site.domain_name
  api_id      = data.aws_api_gateway_rest_api.resize_site.id
  stage_name  = "Prod"
  base_path   = "v1"
}

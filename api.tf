# api.bluemarble.photography: custom domain for the resize API (SAM stack resize-images-app,
# lambdas/resize-images). The 404_redirect Lambda@Edge sends missing image sizes to
# https://api.bluemarble.photography/v1/resize. Created by hand in 2019; imported 2026-11-01.

data "aws_api_gateway_rest_api" "resize" {
  name = "resize-images-app"
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.${var.domain}"
  regional_certificate_arn = aws_acm_certificate_validation.main.certificate_arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "api" {
  domain_name = aws_api_gateway_domain_name.api.domain_name
  api_id      = data.aws_api_gateway_rest_api.resize.id
  stage_name  = "Prod"
  base_path   = "v1"
}

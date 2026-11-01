data "archive_file" "ses_forwarder_lambda_zip_file" {
  type        = "zip"
  output_path = "/tmp/lambda-ses-forwarder-${var.domain}.zip"

  source {
    content  = file("lambdas/ses-forwarder/index.js")
    filename = "index.js"
  }
}

resource "aws_lambda_function" "ses_forwarder" {
  function_name = "sesForwarderBlueMarblePhotography"
  role          = aws_iam_role.lambda_ses_forwarder.arn
  handler       = "index.handler"

  filename         = data.archive_file.ses_forwarder_lambda_zip_file.output_path
  source_code_hash = data.archive_file.ses_forwarder_lambda_zip_file.output_base64sha256

  # tflint-ignore: aws_lambda_function_deprecated_runtime # Frozen until the aws-sdk v3 / nodejs22.x port
  runtime = "nodejs12.x"
  timeout = "10"
}

data "archive_file" "cloudfront_404_redirect_lambda_zip_file" {
  type        = "zip"
  output_path = "/tmp/lambda-404-redirect-${var.domain}.zip"

  source {
    content  = file("lambdas/404_redirect/main.py")
    filename = "main.py"
  }
}

resource "aws_lambda_function" "cloudfront_404_redirect" {
  function_name = "cloudfront-404-apigateway-redirect"
  role          = aws_iam_role.lambda_at_edge.arn
  handler       = "main.lambda_handler"

  filename         = data.archive_file.cloudfront_404_redirect_lambda_zip_file.output_path
  source_code_hash = data.archive_file.cloudfront_404_redirect_lambda_zip_file.output_base64sha256

  runtime = "python3.14"
  timeout = "10"
  publish = true
}

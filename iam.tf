# Deploy permissions for the website workflow's OIDC role (created by infra-aws-base).
data "aws_iam_policy_document" "website_deploy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [module.cdn.site_distribution_arn]
  }

  statement {
    actions = ["ssm:GetParameter"]
    resources = [
      aws_ssm_parameter.website_bucket_name.arn,
      aws_ssm_parameter.website_distribution.arn,
    ]
  }
}

resource "aws_iam_role_policy" "website_deploy" {
  name   = "website-deploy"
  role   = var.website_role_name
  policy = data.aws_iam_policy_document.website_deploy.json
}

# GitHub Actions bridge: credentials start in the site's new account (var.state_account_id,
# infra-aws-base roles) and chain into these roles while the resources still live here.
data "aws_iam_policy_document" "trust_state_account" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.state_account_id}:root"]
    }
  }
}

# Assumed by the aws provider (local runs and infra-* pipelines).
resource "aws_iam_role" "bluemarble_infra" {
  name                 = "bluemarble-infra"
  assume_role_policy   = data.aws_iam_policy_document.trust_state_account.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "bluemarble_infra_admin" {
  role       = aws_iam_role.bluemarble_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Direct deploy permissions for the website workflow's OIDC role (infra-aws-base) once it stops
# chaining into bluemarble-website-deploy.
data "aws_iam_policy_document" "website_deploy" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.main.arn]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]
  }

  statement {
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [module.cdn.main_distribution_arn]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:${var.site_account_id}:parameter/website/*"]
  }
}

resource "aws_iam_role_policy" "website_deploy" {
  provider = aws.site
  name     = "website-deploy"
  role     = "github-actions-website"
  policy   = data.aws_iam_policy_document.website_deploy.json
}

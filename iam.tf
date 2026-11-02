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

data "aws_iam_policy_document" "website_deploy_trust" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.state_account_id}:role/github-actions-website"]
    }
  }
}

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
    resources = [module.cdn_legacy.main_distribution_arn]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.account.account_id}:parameter/website/*"]
  }
}

# Assumed by the website repo's deploy workflow (via github-actions-website).
resource "aws_iam_role" "website_deploy" {
  name                 = "bluemarble-website-deploy"
  assume_role_policy   = data.aws_iam_policy_document.website_deploy_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy" "website_deploy" {
  name   = "website-deploy"
  role   = aws_iam_role.website_deploy.id
  policy = data.aws_iam_policy_document.website_deploy.json
}

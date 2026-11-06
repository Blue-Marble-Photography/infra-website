# bluemarble-infra (530167849052) was the role the provider assumed before the account migration.
# Tofu can't delete the role it runs as, so phase 5c drops it from state and it is deleted by CLI.
removed {
  from = aws_iam_role_policy_attachment.bluemarble_infra_admin

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_iam_role.bluemarble_infra

  lifecycle {
    destroy = false
  }
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
  name   = "website-deploy"
  role   = "github-actions-website"
  policy = data.aws_iam_policy_document.website_deploy.json
}

data "aws_iam_policy" "AmazonSESFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role" "lambda_ses_forwarder" {
  name               = "lambda-ses-forwarder-${var.domain}"
  assume_role_policy = file("templates/iam-lambda-trust.json")
}

resource "aws_iam_role_policy" "lambda_ses_forwarder" {
  name   = "ses-forwarder"
  role   = aws_iam_role.lambda_ses_forwarder.id
  policy = templatefile("templates/iam-ses-forwarder-policy.json", { bucket = "${var.domain}-email" })
}

resource "aws_iam_role_policy_attachment" "lambda_ses_forwarder_ses_full_access" {
  role       = aws_iam_role.lambda_ses_forwarder.name
  policy_arn = data.aws_iam_policy.AmazonSESFullAccess.arn
}

resource "aws_iam_role" "lambda_at_edge" {
  name               = "${var.domain}-lambda-edge"
  assume_role_policy = file("templates/iam-lambda-edge-trust.json")
}

resource "aws_iam_role_policy" "lambda_at_edge_logs" {
  name   = "${var.domain}-logs"
  role   = aws_iam_role.lambda_at_edge.id
  policy = file("templates/iam-logs-policy.json")
}

# GitLab CI: short-lived credentials via OIDC, assumable only from main.
resource "aws_iam_openid_connect_provider" "gitlab" {
  url            = "https://gitlab.com"
  client_id_list = ["https://gitlab.com"]
}

data "aws_iam_policy_document" "gitlab_ci_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "gitlab.com:aud"
      values   = ["https://gitlab.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "gitlab.com:sub"
      values   = ["project_path:${var.gitlab_project_path}:ref_type:branch:ref:main"]
    }
  }
}

resource "aws_iam_role" "gitlab_ci" {
  name                 = "gitlab-ci-${var.domain}"
  assume_role_policy   = data.aws_iam_policy_document.gitlab_ci_trust.json
  max_session_duration = 3600
}

data "aws_iam_policy_document" "gitlab_ci_site_deploy" {
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
    resources = [aws_cloudfront_distribution.main.arn]
  }
}

resource "aws_iam_role_policy" "gitlab_ci_site_deploy" {
  name   = "site-deploy"
  role   = aws_iam_role.gitlab_ci.id
  policy = data.aws_iam_policy_document.gitlab_ci_site_deploy.json
}

# What `sam deploy` (and CloudFormation acting with these credentials) needs for the resize-images-app stack.
data "aws_iam_policy_document" "gitlab_ci_resize_lambda_deploy" {
  statement {
    actions = [
      "cloudformation:CreateChangeSet",
      "cloudformation:DeleteChangeSet",
      "cloudformation:DescribeChangeSet",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackResources",
      "cloudformation:DescribeStacks",
      "cloudformation:ExecuteChangeSet",
      "cloudformation:GetTemplate",
      "cloudformation:GetTemplateSummary",
    ]
    resources = ["arn:aws:cloudformation:${var.aws_region}:${data.aws_caller_identity.account.account_id}:stack/${var.resize_stack_name}/*"]
  }

  statement {
    actions   = ["cloudformation:CreateChangeSet"]
    resources = ["arn:aws:cloudformation:${var.aws_region}:aws:transform/Serverless-2016-10-31"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.sam_artifacts_bucket}"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.sam_artifacts_bucket}/${var.resize_stack_name}/*"]
  }

  statement {
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.account.account_id}:function:ResizeImagesFunction"]
  }

  statement {
    actions   = ["apigateway:GET", "apigateway:PUT", "apigateway:POST", "apigateway:PATCH", "apigateway:DELETE"]
    resources = ["arn:aws:apigateway:${var.aws_region}::/restapis", "arn:aws:apigateway:${var.aws_region}::/restapis/*"]
  }

  statement {
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.resize_stack_name}-ResizeImagesFunctionRole-*"]
  }
}

resource "aws_iam_role_policy" "gitlab_ci_resize_lambda_deploy" {
  name   = "resize-lambda-deploy"
  role   = aws_iam_role.gitlab_ci.id
  policy = data.aws_iam_policy_document.gitlab_ci_resize_lambda_deploy.json
}

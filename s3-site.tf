# Website bucket (508360653481).
# The website repo's deploy workflow syncs _site/ here; viewers reach it only through the main
# distribution (OAC).

#trivy:ignore:AVD-AWS-0090 # Versioning not required; every deploy rewrites the bucket from git
resource "aws_s3_bucket" "main" {
  provider      = aws.site
  bucket        = "bluemarble-site-${var.site_account_id}"
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "main" {
  provider = aws.site
  bucket   = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  provider = aws.site
  bucket   = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0132 # AWS managed S3 key ok
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  provider = aws.site
  bucket   = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.main.arn, "${aws_s3_bucket.main.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.main_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  provider = aws.site
  bucket   = aws_s3_bucket.main.id
  policy   = data.aws_iam_policy_document.site_bucket.json

  depends_on = [aws_s3_bucket_public_access_block.main]
}

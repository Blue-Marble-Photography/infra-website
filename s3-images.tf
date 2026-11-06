# Images bucket (508360653481): the images distribution's origin and the resize Lambda's bucket
# (its SAM-managed role grants the access). Viewers only reach it through the images distribution
# (OAC), so the name doesn't follow the hostname.

#trivy:ignore:AVD-AWS-0090 # Versioning not required
resource "aws_s3_bucket" "images" {
  bucket        = local.images_bucket
  force_destroy = false
}

# Objects the resize Lambda writes belong to the bucket owner; ACLs are disabled.
resource "aws_s3_bucket_ownership_controls" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0132 # AWS managed S3 key ok
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket                                 = aws_s3_bucket.images.id
  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "Intelligent Tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

data "aws_iam_policy_document" "images" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.images.arn, "${aws_s3_bucket.images.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [module.cdn.images_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "images" {
  bucket = aws_s3_bucket.images.id
  policy = data.aws_iam_policy_document.images.json

  depends_on = [aws_s3_bucket_public_access_block.images]
}

resource "aws_s3_object" "images_robots" {
  bucket        = aws_s3_bucket.images.id
  key           = "robots.txt"
  content       = file("${path.module}/templates/robots-images.txt")
  content_type  = "text/plain"
  cache_control = "max-age=86400"
}

resource "aws_s3_object" "images_tdmrep" {
  bucket        = aws_s3_bucket.images.id
  key           = ".well-known/tdmrep.json"
  content       = file("${path.module}/templates/tdmrep.json")
  content_type  = "application/json"
  cache_control = "max-age=86400"
}

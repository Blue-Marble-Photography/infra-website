# Images bucket in the site's own account (508360653481), replacing images.bluemarble.photography.
# Plan: ../../.claude/plans/images-bucket-move.md. Viewers only reach it through the images
# distribution (OAC), so the name doesn't follow the hostname.

locals {
  images_site_bucket = "bluemarble-images-${var.site_account_id}"
}

#trivy:ignore:AVD-AWS-0090 # Versioning not required; the old bucket is the rollback during the move
resource "aws_s3_bucket" "images_site" {
  provider      = aws.site
  bucket        = local.images_site_bucket
  force_destroy = false
}

# Objects the resize Lambda writes from 530167849052 belong to this account; ACLs are disabled.
resource "aws_s3_bucket_ownership_controls" "images_site" {
  provider = aws.site
  bucket   = aws_s3_bucket.images_site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "images_site" {
  provider = aws.site
  bucket   = aws_s3_bucket.images_site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0132 # AWS managed S3 key ok
resource "aws_s3_bucket_server_side_encryption_configuration" "images_site" {
  provider = aws.site
  bucket   = aws_s3_bucket.images_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "images_site" {
  provider                               = aws.site
  bucket                                 = aws_s3_bucket.images_site.id
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

data "aws_iam_policy_document" "images_site" {
  statement {
    sid       = "AllowCloudFrontOAC"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.images_site.arn, "${aws_s3_bucket.images_site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.images.arn, aws_cloudfront_distribution.images_oac_test.arn]
    }
  }

  # The SAM stack names the role ResizeImagesFunctionRole-<random>; match the prefix so a
  # stack redeploy that recreates the role keeps access.
  statement {
    sid       = "AllowResizeLambda"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.images_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.resources_account_id}:root"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${var.resources_account_id}:role/resize-images-app-ResizeImagesFunctionRole-*"]
    }
  }
}

resource "aws_s3_bucket_policy" "images_site" {
  provider = aws.site
  bucket   = aws_s3_bucket.images_site.id
  policy   = data.aws_iam_policy_document.images_site.json

  depends_on = [aws_s3_bucket_public_access_block.images_site]
}

resource "aws_s3_object" "images_site_robots" {
  provider      = aws.site
  bucket        = aws_s3_bucket.images_site.id
  key           = "robots.txt"
  content       = file("templates/robots-images.txt")
  content_type  = "text/plain"
  cache_control = "max-age=86400"
}

resource "aws_s3_object" "images_site_tdmrep" {
  provider      = aws.site
  bucket        = aws_s3_bucket.images_site.id
  key           = ".well-known/tdmrep.json"
  content       = file("templates/tdmrep.json")
  content_type  = "application/json"
  cache_control = "max-age=86400"
}

# Temporary: proves a distribution in 530167849052 can read this bucket through OAC before the
# images distribution depends on it. Remove after the check (plan, prep step 6).
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

#trivy:ignore:AVD-AWS-0010 # Temporary test distribution
#trivy:ignore:AVD-AWS-0011 # Temporary test distribution
#trivy:ignore:AVD-AWS-0013 # Default *.cloudfront.net certificate; temporary test distribution
resource "aws_cloudfront_distribution" "images_oac_test" {
  comment         = "Temporary OAC check for ${local.images_site_bucket}"
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.images_site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-${local.images_site_bucket}"
  }

  default_cache_behavior {
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.images_site_bucket}"
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

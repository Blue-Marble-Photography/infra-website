#trivy:ignore:AVD-AWS-0090 # Versioning not required
#trivy:ignore:AVD-AWS-0320 # Bucket names match the CloudFront/SES domain names
resource "aws_s3_bucket" "main" {
  bucket        = var.domain
  force_destroy = false
}

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = templatefile("templates/s3-cloudfront-policy.json", {
    bucket              = var.domain
    distribution_arn    = aws_cloudfront_distribution.main.arn
    delegate_account_id = ""
  })
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#trivy:ignore:AVD-AWS-0132 # AWS managed S3 key ok
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#trivy:ignore:AVD-AWS-0090 # Versioning not required
#trivy:ignore:AVD-AWS-0320 # Bucket names match the CloudFront/SES domain names
resource "aws_s3_bucket" "images" {
  bucket        = "images.${var.domain}"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "images" {
  bucket = aws_s3_bucket.images.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "images" {
  bucket = aws_s3_bucket.images.id
  policy = templatefile("templates/s3-cloudfront-policy.json", {
    bucket              = "images.${var.domain}"
    distribution_arn    = aws_cloudfront_distribution.images.arn
    delegate_account_id = var.site_account_id
  })
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "images" {
  bucket                                 = aws_s3_bucket.images.id
  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "Intelligent Tiering"
    status = "Enabled"

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
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

#trivy:ignore:AVD-AWS-0090 # Versioning not required
#trivy:ignore:AVD-AWS-0320 # Bucket names match the CloudFront/SES domain names
resource "aws_s3_bucket" "email" {
  bucket        = "${var.domain}-email"
  force_destroy = false
}

resource "aws_s3_bucket_acl" "email" {
  bucket = aws_s3_bucket.email.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "email" {
  bucket = aws_s3_bucket.email.id
  policy = templatefile("templates/s3-ses-policy.json", {
    bucket     = "${var.domain}-email"
    account_id = data.aws_caller_identity.account.account_id
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "email" {
  bucket                                 = aws_s3_bucket.email.id
  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "Delete Old Emails"
    status = "Enabled"

    filter {
      prefix = "incoming/"
    }

    expiration {
      days = 7
    }
  }
}

#trivy:ignore:AVD-AWS-0132 # AWS managed S3 key ok
resource "aws_s3_bucket_server_side_encryption_configuration" "email" {
  bucket = aws_s3_bucket.email.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "email" {
  bucket = aws_s3_bucket.email.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# robots.txt for images.bluemarble.photography. Without it the request 404s into the
# resize redirect. AI crawler list mirrors the site's robots.txt.
resource "aws_s3_object" "images_robots" {
  bucket        = aws_s3_bucket.images.id
  key           = "robots.txt"
  content       = file("templates/robots-images.txt")
  content_type  = "text/plain"
  cache_control = "max-age=86400"
}

# TDMRep opt-out (W3C TDM Reservation Protocol); the site serves the same file from the website repo.
resource "aws_s3_object" "images_tdmrep" {
  bucket        = aws_s3_bucket.images.id
  key           = ".well-known/tdmrep.json"
  content       = file("templates/tdmrep.json")
  content_type  = "application/json"
  cache_control = "max-age=86400"
}

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
  policy = templatefile("templates/s3-cf-oai-policy.json", {
    oai_arn             = aws_cloudfront_origin_access_identity.oai.iam_arn
    bucket              = var.domain
    delegate_account_id = ""
  })
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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
  policy = templatefile("templates/s3-cf-oai-policy.json", {
    oai_arn             = aws_cloudfront_origin_access_identity.oai.iam_arn
    bucket              = "images.${var.domain}"
    delegate_account_id = var.site_account_id
  })
}

resource "aws_s3_bucket_website_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }

  routing_rule {
    condition {
      http_error_code_returned_equals = "404"
      key_prefix_equals               = ""
    }

    redirect {
      host_name               = "api.${var.domain}"
      http_redirect_code      = "307"
      protocol                = "https"
      replace_key_prefix_with = "v1/resize?path="
    }
  }
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

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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

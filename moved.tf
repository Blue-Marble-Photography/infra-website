# Phase 5c renames (phase5-cleanup.md); delete once applied.

moved {
  from = aws_s3_bucket.images_site
  to   = aws_s3_bucket.images
}

moved {
  from = aws_s3_bucket_ownership_controls.images_site
  to   = aws_s3_bucket_ownership_controls.images
}

moved {
  from = aws_s3_bucket_public_access_block.images_site
  to   = aws_s3_bucket_public_access_block.images
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.images_site
  to   = aws_s3_bucket_server_side_encryption_configuration.images
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.images_site
  to   = aws_s3_bucket_lifecycle_configuration.images
}

moved {
  from = aws_s3_bucket_policy.images_site
  to   = aws_s3_bucket_policy.images
}

moved {
  from = aws_s3_object.images_site_robots
  to   = aws_s3_object.images_robots
}

moved {
  from = aws_s3_object.images_site_tdmrep
  to   = aws_s3_object.images_tdmrep
}

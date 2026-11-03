locals {
  # With no certificate the distributions answer only on their *.cloudfront.net domains.
  aliases_enabled = var.certificate_arn != null
}

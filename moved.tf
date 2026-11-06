# Phase 5b-2 renames (phase5-cleanup.md); delete once applied.

moved {
  from = aws_route53_record.site_root
  to   = aws_route53_record.root
}

moved {
  from = aws_route53_record.site_root_ipv6
  to   = aws_route53_record.root_ipv6
}

moved {
  from = aws_route53_record.site_images
  to   = aws_route53_record.images
}

moved {
  from = aws_route53_record.site_images_ipv6
  to   = aws_route53_record.images_ipv6
}

moved {
  from = aws_route53_record.site_api
  to   = aws_route53_record.api
}

moved {
  from = aws_route53_record.site_mx
  to   = aws_route53_record.mx
}

moved {
  from = aws_route53_record.site_txt
  to   = aws_route53_record.txt
}

moved {
  from = aws_route53_record.site_dmarc
  to   = aws_route53_record.dmarc
}

moved {
  from = aws_route53_record.site_proton_dkim
  to   = aws_route53_record.proton_dkim
}

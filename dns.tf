# The old account's hosted zone was retired in phase 5b; Route 53 deletes its apex NS and SOA
# records with the zone, so they are only dropped from state here.
removed {
  from = aws_route53_record.nameservers

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_route53_record.soa

  lifecycle {
    destroy = false
  }
}

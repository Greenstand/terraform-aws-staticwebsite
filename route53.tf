locals {
  route53_domain = var.route53_domain != "" ? var.route53_domain : var.domain
}

resource "aws_acm_certificate" "cert" {
  domain_name       = local.bucket_name
  validation_method = "DNS"
}


resource "aws_route53_zone" "main" {
  name = local.route53_domain
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  #type    = "A"

  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }

  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  ttl     = 60
  records         = [each.value.record]
  name            = each.value.name
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.app : record.fqdn]
}

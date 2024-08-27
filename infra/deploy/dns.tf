data "aws_route53_zone" "zone" {
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}" # 'lookup' look up in the subdomain map defined
  type    = "CNAME"                                                                            // Canonical name that map a dns to another. Map the request to ALB dns
  ttl     = "300"  # determining how often DNS records are refreshed.                                                                            // time to live How often new changes get reflected 

  records = [aws_lb.api.dns_name]
}

resource "aws_acm_certificate" "cert" {
  domain_name       = aws_route53_record.app.name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true # flag ensures that if the resource needs to be replaced, the new certificate is created before the old one is destroyed, minimizing downtime.
  }
}


/* 
  This resource creates the necessary DNS records to validate the domain for the SSL/TLS certificate.
 */
resource "aws_route53_record" "cert_validation" {
  for_each = { // Create a record for each validation option
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true # Allows the record to be overwritten if it already exists.
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60 # allowing the DNS change to propagate quickly.
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

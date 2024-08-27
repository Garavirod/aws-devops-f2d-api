data "aws_route53_zone" "zone" {
  name = "${var.dns_zone_name}."
}

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "${lookup(var.subdomain, terraform.workspace)}.${data.aws_route53_zone.zone.name}" # 'lookup' look up in the subdomain map defined
  type    = "CNAME"                                                                            // Canonical name that map a dns to another. Map the request to ALB dns
  ttl     = "300"                                                                              // time to live How often new changes get reflected 

  records = [aws_lb.api.dns_name]
}

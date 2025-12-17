# for custom domain with ACM
# resource "aws_route53_zone" "main" {
#   name = "nkajitani.com"
# }

# resource "aws_route53_record" "main" {
#   for_each = {
#     for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       type   = dvo.resource_record_type
#       record = dvo.resource_record_value
#     }
#   }

#   zone_id = aws_route53_zone.main.zone_id
#   name    = each.value.name
#   type    = each.value.type
#   ttl     = 60
#   records = [each.value.record]
# }

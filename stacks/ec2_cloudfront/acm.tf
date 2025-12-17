# resource "aws_acm_certificate" "cloudfront" {
#   provider          = aws.acm
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#   key_algorithm     = "RSA_2048"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.project_name}-cloudfront-acms"
#   }
# }

# resource "aws_acm_certificate_validation" "cloudfront" {
#   provider        = aws.acm
#   certificate_arn = aws_acm_certificate.cloudfront.arn

#   validation_record_fqdns = [
#     for record in aws_route53_record.main : record.fqdn
#   ]
# }

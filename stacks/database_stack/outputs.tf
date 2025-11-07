output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "aurora_writer_endpoint" {
  value     = aws_rds_cluster.aurora.endpoint
  sensitive = true
}

output "aurora_reader_endpoint" {
  value     = aws_rds_cluster.aurora.reader_endpoint
  sensitive = true
}

output "bastion_public_ips" {
  value = { for k, v in aws_instance.bastion : k => v.public_ip }
}
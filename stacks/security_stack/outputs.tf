output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "security_group_ids" {
  description = "Security Group IDs"
  value = {
    alb     = aws_security_group.alb.id
    web     = aws_security_group.web.id
    db      = aws_security_group.db.id
    bastion = aws_security_group.bastion.id
  }
}

output "vpc_endpoint_ids" {
  description = "VPC Endpoint IDs"
  value = {
    s3  = aws_vpc_endpoint.s3.id
    ec2 = aws_vpc_endpoint.ec2.id
    ssm = aws_vpc_endpoint.ssm.id
  }
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = [for s in aws_subnet.private : s.id]
}
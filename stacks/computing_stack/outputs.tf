# ==========================================
# VPC & Network Outputs
# ==========================================
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

# ==========================================
# ALB Outputs
# ==========================================
output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.main.arn
}

# ==========================================
# ASG Outputs
# ==========================================
output "asg_name" {
  description = "Auto Scaling Group Name"
  value       = aws_autoscaling_group.main.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.main.id
}

# ==========================================
# Access URL
# ==========================================
output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.main.dns_name}/"
}
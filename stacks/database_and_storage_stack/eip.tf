resource "aws_eip" "public" {
  domain = "vpc"

  for_each = var.subnets.public

  tags = {
    Name = "${var.project_name}-eip-${each.key}"
  }
}

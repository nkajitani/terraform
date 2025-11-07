resource "aws_eip" "public" {
  domain = "vpc"

  for_each = aws_subnet.public

  tags = {
    Name = "${var.project_name}-eip-${each.key}"
  }
}
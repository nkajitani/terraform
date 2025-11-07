resource "aws_nat_gateway" "main" {
  for_each = var.public_subnets

  allocation_id     = aws_eip.public[each.key].id
  connectivity_type = "public"
  subnet_id         = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project_name}-natgw-${each.key}"
  }
}
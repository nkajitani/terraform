resource "aws_nat_gateway" "main" {
  for_each = var.subnets.public

  allocation_id = aws_eip.public[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${var.project_name}-natgw-${each.key}"
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  for_each          = var.subnets.public
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id

  for_each          = var.subnets.private
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-private-subnet-${each.key}"
  }
}

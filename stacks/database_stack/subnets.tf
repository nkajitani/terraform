resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id

  for_each          = var.public_subnets
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-public-subnet-${each.key}"
  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id

  for_each          = var.private_subnets
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-private-subnet-${each.key}"
  }
}

resource "aws_subnet" "rds" {
  vpc_id = aws_vpc.main.id

  for_each          = var.rds_subnets
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.project_name}-rds-subnet-${each.key}"
  }
}

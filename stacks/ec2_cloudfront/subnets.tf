resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet.cidr
  availability_zone = var.public_subnet.az

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

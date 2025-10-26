/*
  IGW and public subnet stack
*/
# local values
locals {
  public_subnets = {
    a = { cidr = "10.0.1.0/24", az_suffix = "a" }
    c = { cidr = "10.0.2.0/24", az_suffix = "c" }
  }
}

# vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "study-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "study-igw"
  }
}

# public subnet
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = "ap-northeast-1${each.value.az_suffix}"

  tags = {
    Name = "study-public-${each.key}"
  }
}

# Route Table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "study-public-rt"
  }
}

# Route Table Association for public subnet
resource "aws_route_table_association" "public_rta" {
  for_each = local.public_subnets

  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public[each.key].id
}

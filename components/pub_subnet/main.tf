/*
  IGW and public subnet stack
  memo:
    create automatically Route Table
*/
# local values
locals {
  public_subnets = {
    a = { cidr = "10.0.1.0/24", az_suffix = "a" }
    c = { cidr = "10.0.2.0/24", az_suffix = "c" }
  }
}

# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "study-public"
  }
}

# IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "study-igw"
  }
}

# public subnet
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = "ap-northeast-1${each.value.az_suffix}"

  tags = {
    Name = "study-public-${each.key}"
  }
}

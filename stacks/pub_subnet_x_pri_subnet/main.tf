/*
  public and private subnets stack
*/
# local values
locals {
  public_subnets = {
    a = { cidr = "10.0.1.0/24", az_suffix = "a" }
    c = { cidr = "10.0.2.0/24", az_suffix = "c" }
  }

  private_subnets = {
    a = { cidr = "10.0.3.0/24", az_suffix = "a" }
    c = { cidr = "10.0.4.0/24", az_suffix = "c" }
  }
}

# vpc
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "study-vpc"
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

# private subnet
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = "ap-northeast-1${each.value.az_suffix}"

  tags = {
    Name = "study-private-${each.key}"
  }
}

# EIP
resource "aws_eip" "nats" {
  domain = "vpc"

  for_each = local.public_subnets

  tags = {
    Name = "study-nat-eip-${each.value.az_suffix}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nats" {
  for_each = local.public_subnets

  allocation_id = aws_eip.nats[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "study-nat-gateway-${each.value.az_suffix}"
  }

  depends_on = [ aws_internet_gateway.gw ]
}

# Route Table for public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "study-public-rt"
  }
}

# Route Table Association for public subnet
resource "aws_route_table_association" "public_rt_assoc" {
  for_each = local.public_subnets

  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public[each.key].id
}

# Route Table for private subnet
resource "aws_route_table" "private_rts" {
  vpc_id = aws_vpc.main.id
  for_each = local.private_subnets

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nats[each.key].id
  }

  tags = {
    Name = "study-private-rt-${each.value.az_suffix}"
  }
}

# Route Table Association for private subnet
resource "aws_route_table_association" "private_rt_assoc" {
  for_each = local.private_subnets

  route_table_id = aws_route_table.private_rts[each.key].id
  subnet_id      = aws_subnet.private[each.key].id
}

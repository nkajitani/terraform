/*
  Phase 2: Security and Access Control Stack
  - Security Groups
  - Network ACLs
  - VPC Endpoints
*/

# ==========================================
# VPC
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "study-vpc"
  }
}

# ==========================================
# Internet Gateway
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "study-igw"
  }
}

# ==========================================
# Local Values
# ==========================================
locals {
  public_subnets = {
    a = { cidr = "10.0.1.0/24", az_suffix = "a" }
    c = { cidr = "10.0.3.0/24", az_suffix = "c" }
  }
  private_subnets = {
    a = { cidr = "10.0.2.0/24", az_suffix = "a" }
    c = { cidr = "10.0.4.0/24", az_suffix = "c" }
  }
}

# ==========================================
# Public Subnets and Route Tables
# ==========================================
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = "ap-northeast-1${each.value.az_suffix}"

  tags = {
    Name = "study-public-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "study-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Private Subnets and Route Tables with NAT Gateway
# ==========================================
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = "ap-northeast-1${each.value.az_suffix}"

  tags = {
    Name = "study-private-${each.key}"
  }
}

## NAT EIP
resource "aws_eip" "nats" {
  domain = "vpc"

  for_each = local.public_subnets

  tags = {
    Name = "study-nat-eip-${each.key}"
  }
}

## NAT Gateway
resource "aws_nat_gateway" "nats" {
  for_each = local.public_subnets

  allocation_id = aws_eip.nats[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "study-nat-gateway-${each.key}"
  }
}

resource "aws_route_table" "private" {
  vpc_id   = aws_vpc.main.id
  for_each = local.private_subnets

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nats[each.key].id
  }

  tags = {
    Name = "study-private-rt-${each.key}"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ==========================================
# Security Groups
# ==========================================
## ALB用Security Group
resource "aws_security_group" "alb" {
  name        = "study-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-alb-sg"
  }
}

## Web Server用Security Group
resource "aws_security_group" "web" {
  name        = "study-web-sg"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-web-sg"
  }
}

## DB用Security Group
resource "aws_security_group" "db" {
  name        = "study-db-sg"
  description = "Security group for database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from Web Servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-db-sg"
  }
}

## Bastion Host用Security Group
resource "aws_security_group" "bastion" {
  name        = "study-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-bastion-sg"
  }
}

# ==========================================
# Network ACLs
# ==========================================
## public subnets acl
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.public : s.id]

  # Inbound Rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "study-public-nacl"
  }
}

## Private Subnet用Network ACL
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [for s in aws_subnet.private : s.id]

  ### Inbound Rules
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  ### Outbound Rules
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "study-private-nacl"
  }
}

# ==========================================
# VPC Endpoints
# ==========================================
## S3 VPC Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    for rt in aws_route_table.private : rt.id
  ]

  tags = {
    Name = "study-s3-endpoint"
  }
}

## EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "study-ec2-endpoint"
  }
}

## SSM VPC Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.private : s.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  tags = {
    Name = "study-ssm-endpoint"
  }
}

# VPC Endpoint用Security Group
resource "aws_security_group" "vpc_endpoint" {
  name        = "study-vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "study-vpc-endpoint-sg"
  }
}
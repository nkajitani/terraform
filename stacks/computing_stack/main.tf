# ==========================================
# DataSource
# ==========================================
data "aws_ssm_parameter" "amzn2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ==========================================
# Local Values
# ==========================================
locals {
  public_subnets = {
    a = { cidr = "10.0.1.0/24", az = "ap-northeast-1a" }
    c = { cidr = "10.0.3.0/24", az = "ap-northeast-1c" }
  }
  private_subnets = {
    a = { cidr = "10.0.2.0/24", az = "ap-northeast-1a" }
    c = { cidr = "10.0.4.0/24", az = "ap-northeast-1c" }
  }
  common_tags = {
    Project     = "study-terraform"
    Environment = "dev"
    ManagedBy   = "terraform"
    Phase       = "phase3"
  }
}

# ==========================================
# VPC
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    {
      Name = "study-vpc"
    },
    local.common_tags
  )
}

# ==========================================
# Internet Gateway
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = "study-igw"
    },
    local.common_tags
  )
}

# ==========================================
# Public Subnets and Route Tables
# ==========================================
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  # ALB用
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name = "study-public-subnets-${each.key}"
    },
    local.common_tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    {
      Name = "study-public-rt"
    },
    local.common_tags
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# Private Subnets and Route Tables with NAT Gateway
# ==========================================
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    {
      Name = "study-private-subnets-${each.key}"
    },
    local.common_tags
  )
}

resource "aws_eip" "nats" {
  domain = "vpc"

  for_each = local.public_subnets

  tags = merge(
    {
      Name = "study-nat-eip-${each.key}"
    },
    local.common_tags
  )
}

resource "aws_nat_gateway" "nat_gws" {
  for_each = local.public_subnets

  allocation_id = aws_eip.nats[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  depends_on = [aws_internet_gateway.igw]

  tags = merge(
    {
      Name = "study-nat-gw-${each.key}"
    },
    local.common_tags
  )

}
resource "aws_route_table" "private" {
  vpc_id   = aws_vpc.main.id
  for_each = local.private_subnets

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gws[each.key].id
  }

  tags = merge(
    {
      Name = "study-private-rt"
    },
    local.common_tags
  )
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}


# ==========================================
# ALB Security Groups
# ==========================================
resource "aws_security_group" "alb" {
  name        = "study-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS from Internet"
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

  tags = merge(
    {
      Name = "study-alb-sg"
    },
    local.common_tags
  )
}

# ==========================================
# Web Server Security Groups
# ==========================================
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

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "study-web-sg"
    },
    local.common_tags
  )
}

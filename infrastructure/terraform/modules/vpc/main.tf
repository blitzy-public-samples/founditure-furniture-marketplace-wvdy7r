# Human Tasks:
# 1. Ensure AWS credentials are properly configured
# 2. Verify the target AWS region supports at least 3 availability zones
# 3. Review and adjust CIDR ranges if they conflict with existing networks
# 4. Ensure proper IAM permissions for Terraform execution

# AWS Provider version ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Local variables for VPC configuration
locals {
  vpc_cidr            = "10.0.0.0/16"
  project_name        = "founditure"
  environment         = var.environment
  public_subnet_count = 3
  private_subnet_count = 3
  enable_nat_gateway  = true
  single_nat_gateway  = false
}

# Requirement: Multi-AZ Deployment (3.5 Scalability Architecture)
# Fetch available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Requirement: Network Infrastructure (3.1 High-Level Architecture Overview/Network Layer)
# Create the main VPC
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.project_name}-${local.environment}-vpc"
    Environment = local.environment
    Project     = local.project_name
  }
}

# Requirement: Security Architecture (3.6 Security Architecture)
# Create public subnets for internet-facing resources
resource "aws_subnet" "public" {
  count             = local.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.project_name}-${local.environment}-public-${count.index + 1}"
    Type = "Public"
  }
}

# Requirement: Security Architecture (3.6 Security Architecture)
# Create private subnets for internal resources
resource "aws_subnet" "private" {
  count             = local.private_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + local.public_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.project_name}-${local.environment}-private-${count.index + 1}"
    Type = "Private"
  }
}

# Requirement: Network Infrastructure (3.1 High-Level Architecture Overview/Network Layer)
# Create Internet Gateway for public subnet internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-${local.environment}-igw"
  }
}

# Requirement: Multi-AZ Deployment (3.5 Scalability Architecture)
# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = local.enable_nat_gateway ? (local.single_nat_gateway ? 1 : local.private_subnet_count) : 0
  vpc   = true

  tags = {
    Name = "${local.project_name}-${local.environment}-nat-eip-${count.index + 1}"
  }
}

# Requirement: Security Architecture (3.6 Security Architecture)
# Create NAT Gateways for private subnet internet access
resource "aws_nat_gateway" "main" {
  count         = local.enable_nat_gateway ? (local.single_nat_gateway ? 1 : local.private_subnet_count) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${local.project_name}-${local.environment}-nat-gw-${count.index + 1}"
  }
}

# Requirement: Network Infrastructure (3.1 High-Level Architecture Overview/Network Layer)
# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.project_name}-${local.environment}-public-rt"
  }
}

# Requirement: Security Architecture (3.6 Security Architecture)
# Create route tables for private subnets
resource "aws_route_table" "private" {
  count  = local.enable_nat_gateway ? (local.single_nat_gateway ? 1 : local.private_subnet_count) : 1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = local.enable_nat_gateway ? aws_nat_gateway.main[count.index].id : null
  }

  tags = {
    Name = "${local.project_name}-${local.environment}-private-rt-${count.index + 1}"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = local.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route tables
resource "aws_route_table_association" "private" {
  count          = local.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = local.single_nat_gateway ? aws_route_table.private[0].id : aws_route_table.private[count.index].id
}
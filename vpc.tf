resource "aws_vpc" "vpc" {
  cidr_block           = "20.0.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "Web-VPC"
    Environment = "development"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "IRS-Test2-IGW"
    Environment = "development"
  }
}

resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name        = "IRS-Test-NAT-Gateway"
    Environment = "development"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = 3
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index * 4)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "Public-Subnet-${count.index + 1}"
    Environment = "development"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = 3
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, count.index * 4 + 2)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "Private-Subnet-${count.index + 1}"
    Environment = "development"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "Public-Route-Table"
    Environment = "development"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "Private-Route-Table"
    Environment = "development"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

data "aws_secretsmanager_secret" "terraform" {
  name = "terrafrom"
}

data "aws_secretsmanager_secret_version" "terraform_tfvars" {
  secret_id = data.aws_secretsmanager_secret.terraform.id
}

locals {
  terraform = jsondecode(data.aws_secretsmanager_secret_version.terraform_tfvars.secret_string)
}
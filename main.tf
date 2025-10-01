#
# main.tf
#
# This Terraform code deploys the following AWS resources:
# - A Virtual Private Cloud (VPC)
# - Two public subnets and two private subnets
# - An Internet Gateway and a NAT Gateway for internet access
# - Route tables for both public and private subnets
# - An EC2 instance running a simple web server (Apache)
# - An Application Load Balancer (ALB) to distribute traffic to the EC2 instance
# - Security groups to control traffic flow
# - A VPC Gateway Endpoint for S3
#

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# -----------------
# VPC and Subnets
# -----------------

# Create a new VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "app-vpc"
  }
}

# Create public subnets in two different Availability Zones
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-b"
  }
}

# Create private subnets in two different Availability Zones
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet-b"
  }
}

# -----------------
# Internet Access
# -----------------

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
    Name = "main-internet-gateway"
  }
}

# Create a public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Create an EIP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  # The 'vpc' argument is deprecated and no longer needed for EIPs in a VPC.
}

# Create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id
  tags = {
    Name = "nat-gateway"
  }
}

# Create a private route table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "private-route-table"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# -----------------
# Security Groups
# -----------------

# Security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow inbound traffic from the ALB"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Security group for the Application Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "lb-security-group"
  description = "Allow inbound HTTP traffic to the ALB"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sg"
  }
}

# -----------------
# EC2 Instance
# -----------------

# User data script to install and configure Apache web server
resource "aws_instance" "app_instance" {
  ami           = "ami-0fd3ac4abb734302a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform deployed EC2!</h1>" > /var/www/html/index.html
              EOF
  tags = {
    Name = "app-instance"
  }
}

# -----------------
# Application Load Balancer
# -----------------

# Create a Target Group
resource "aws_lb_target_group" "app_target_group" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "instance"
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
  }
}

# Attach the EC2 instance to the Target Group
resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_target_group.arn
  target_id        = aws_instance.app_instance.id
  port             = 80
}

# Create the Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  tags = {
    Name = "app-lb"
  }
}

# Create a Listener for the ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# -----------------
# VPC Gateway Endpoint
# -----------------

# Create a VPC Gateway Endpoint for S3 to allow instances in the private subnet
# to access S3 services without an Internet Gateway or NAT Gateway.
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id       = aws_vpc.app_vpc.id
  service_name = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [aws_route_table.private_rt.id]
  tags = {
    Name = "s3-gateway-endpoint"
  }
}

# -----------------
# Outputs
# -----------------

# Output the DNS name of the Load Balancer
output "lb_dns_name1" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

# Output the VPC ID
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.app_vpc.id
}

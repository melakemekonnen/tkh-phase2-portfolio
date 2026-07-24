provider "aws" {
  region = "us-east-1"
}

# ====================================================================
# TITAN FINTECH: THE MONITORED FORTRESS
# ====================================================================

# --- LAYER 1: THE PERIMETER ---

# The Neighborhood — Titan FinTech's isolated network
resource "aws_vpc" "titan_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "TKH-Titan-Prod-VPC"
  }
}

# The Public Block — where the Zero Trust server lives
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.titan_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TKH-Titan-Public-Subnet"
  }
}

# The Front Door — connects VPC to internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.titan_vpc.id

  tags = {
    Name = "TKH-Titan-IGW"
  }
}

# The GPS — tells traffic how to reach the internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.titan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "TKH-Titan-Public-RT"
  }
}

# Connect the GPS to the Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# --- LAYER 2: THE WIRETAP ---

# The Recorder — where all network traffic gets logged
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/tkh/titan-prod-vpc-logs"
  retention_in_days = 1

  tags = {
    Name = "TKH-Titan-Flow-Logs"
  }
}

# The Wiretap — captures ALL VPC traffic to CloudWatch
resource "aws_flow_log" "vpc_wiretap" {
  vpc_id          = aws_vpc.titan_vpc.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
}

# --- LAYER 3: ZERO TRUST COMPUTE ---

# The Locked Door — zero inbound, all outbound
resource "aws_security_group" "zero_trust_sg" {
  name        = "TKH-Titan-Zero-Trust-SG"
  description = "Zero inbound rules - SSM outbound only"
  vpc_id      = aws_vpc.titan_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TKH-Titan-Zero-Trust-SG"
  }
}

# The Zero Trust Server — no SSH, no inbound ports
resource "aws_instance" "zero_trust_server" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.zero_trust_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true

  tags = {
    Name = "TKH-Titan-Zero-Trust-Node"
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "sabotaged_sg" {
  name        = "tlab7-secured-sg"
  description = "Security group with SSH restricted to my home IP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["23.30.2.190/32"]
  }
}

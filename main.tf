provider "aws" {
  region = "us-east-1"
}

# The Guardrail
resource "aws_budgets_budget" "tlab_budget" {
  name              = "TLAB-Strict-Budget"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["melakemekonnen100@gmail.com"]
  }
}

# Random ID for globally unique S3 bucket naming
resource "random_id" "bucket_id" {
  byte_length = 4
}

# The private vault for Titan FinTech financial data
resource "aws_s3_bucket" "vault" {
  bucket = "titan-fintech-vault-mm-${random_id.bucket_id.hex}"

  tags = {
    Name        = "Titan-FinTech-Vault"
    Environment = "Production"
  }
}

# Lock the vault - block all public access
resource "aws_s3_bucket_public_access_block" "vault_access" {
  bucket = aws_s3_bucket.vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# The badge — Titan EC2 Vault Role
resource "aws_iam_role" "ec2_vault_role" {
  name = "Titan-EC2-Vault-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# What the badge wearer can do
resource "aws_iam_role_policy" "vault_policy" {
  name = "titan-vault-write-policy"
  role = aws_iam_role.ec2_vault_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = [
          aws_s3_bucket.vault.arn,
          "${aws_s3_bucket.vault.arn}/*"
        ]
      }
    ]
  })
}

# The lanyard — connects the badge to the EC2 server
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "Titan-EC2-Vault-Profile"
  role = aws_iam_role.ec2_vault_role.name
}

# The employee — EC2 server wearing the vault role
resource "aws_instance" "server" {
  ami                  = "ami-0c7217cdde317cfec"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "Titan-FinTech-Server"
  }
}
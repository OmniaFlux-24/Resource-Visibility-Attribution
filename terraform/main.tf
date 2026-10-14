# RVA SaaS Platform - Production Infrastructure
# Terraform configuration for AWS deployment

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state storage (S3 + DynamoDB for locking)
  backend "s3" {
    bucket         = "rva-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "rva-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "RVA"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ============================================================================
# VPC & Networking
# ============================================================================
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "rva-${var.environment}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = var.environment != "production"
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# ============================================================================
# PostgreSQL 17 RDS Instance
# ============================================================================
module "postgres17" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "rva-${var.environment}-postgres17"
  engine     = "postgres"
  engine_version = "17"
  family     = "postgres17"
  instance_class = var.db_instance_class

  allocated_storage     = 100
  max_allocated_storage = 500
  storage_encrypted     = true

  db_name  = "rva_db"
  username = "rva_admin"
  port     = 5432

  manage_master_user_password = true
  
  multi_az               = var.environment == "production"
  maintenance_window     = "Mon:03:00-Mon:04:00"
  backup_window          = "02:00-03:00"
  backup_retention_period = var.environment == "production" ? 30 : 7

  vpc_security_group_ids = [module.db_security_group.security_group_id]
  subnet_ids             = module.vpc.private_subnets

  deletion_protection = var.environment == "production"
  skip_final_snapshot = var.environment != "production"

  performance_insights_enabled = true
  monitoring_interval          = 60

  tags = {
    Component = "Database"
  }
}

# ============================================================================
# Security Groups
# ============================================================================
module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "rva-${var.environment}-db-sg"
  description = "Security group for RVA PostgreSQL 17 RDS"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]
}
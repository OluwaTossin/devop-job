# =============================================================================
# DevOps Job Portal - Main Terraform Configuration
# =============================================================================
# 
# This file contains the main Terraform configuration for the DevOps job portal
# including provider requirements, AWS configuration, and shared resources.
# 
# Author: DevOps Job Portal Team
# Date: September 2025
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # S3 backend for storing Terraform state
  backend "s3" {
    bucket         = "terraform-state-devops-job-portal"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
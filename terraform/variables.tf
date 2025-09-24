# =============================================================================
# DevOps Job Portal - Variable Definitions
# =============================================================================
# 
# This file defines all input variables for the DevOps job portal infrastructure
# including validation rules and default values for different environments.
# 
# Author: DevOps Job Portal Team
# Date: September 2025
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-job-portal"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}

variable "allowed_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["*"]
}

variable "admin_username" {
  description = "Admin username for portal access"
  type        = string
  default     = "admin"
  sensitive   = true
}

# Local values for consistent naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
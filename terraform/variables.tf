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

# Database Configuration Variables
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 1
}

# Use an existing DB subnet group instead of creating one
variable "use_existing_db_subnet_group" {
  description = "When true, use an existing DB subnet group instead of creating it"
  type        = bool
  default     = false
}

variable "existing_db_subnet_group_name" {
  description = "Name of the existing DB subnet group to use when use_existing_db_subnet_group is true"
  type        = string
  default     = null
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}

# Lambda Configuration Variables
variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

# Additional Production Settings
variable "enable_deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
  default     = false
}

variable "enable_backup_encryption" {
  description = "Enable backup encryption for RDS"
  type        = bool
  default     = false
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for RDS"
  type        = bool
  default     = false
}

# Common Tags Override
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Local values for consistent naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge({
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }, var.common_tags)
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways to create (1 for dev to save cost, 2 for prod for HA)"
  type        = number
  default     = 1
}
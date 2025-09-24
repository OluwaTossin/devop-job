# S3 bucket for frontend hosting
output "frontend_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_website_url" {
  description = "Website URL for the frontend application"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}

# API Gateway
output "api_gateway_url" {
  description = "Base URL for API Gateway"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

# RDS
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

# Lambda Functions
output "lambda_functions" {
  description = "Lambda function names and ARNs"
  value = {
    submit_cv = {
      name = aws_lambda_function.submit_cv.function_name
      arn  = aws_lambda_function.submit_cv.arn
    }
    list_applications = {
      name = aws_lambda_function.list_applications.function_name
      arn  = aws_lambda_function.list_applications.arn
    }
    get_application = {
      name = aws_lambda_function.get_application.function_name
      arn  = aws_lambda_function.get_application.arn
    }
  }
}

# CloudWatch Log Groups
output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value = [
    aws_cloudwatch_log_group.submit_cv.name,
    aws_cloudwatch_log_group.list_applications.name,
    aws_cloudwatch_log_group.get_application.name
  ]
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
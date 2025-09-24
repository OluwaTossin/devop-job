# Security Group for Lambda functions
resource "aws_security_group" "lambda" {
  name        = "${local.name_prefix}-lambda-sg"
  description = "Security group for Lambda functions"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-sg"
  })
}

# IAM role for Lambda functions
resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Lambda functions
resource "aws_iam_role_policy" "lambda" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.cv_storage.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "submit_cv" {
  name              = "/aws/lambda/${local.name_prefix}-submit-cv"
  retention_in_days = var.environment == "prod" ? 14 : 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "list_applications" {
  name              = "/aws/lambda/${local.name_prefix}-list-applications"
  retention_in_days = var.environment == "prod" ? 14 : 7

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "get_application" {
  name              = "/aws/lambda/${local.name_prefix}-get-application"
  retention_in_days = var.environment == "prod" ? 14 : 7

  tags = local.common_tags
}

# Lambda function for CV submission
resource "aws_lambda_function" "submit_cv" {
  filename         = local.lambda_packages.submit_cv
  function_name    = "${local.name_prefix}-submit-cv"
  role            = aws_iam_role.lambda.arn
  handler         = "submit_cv.lambda_handler"
  source_code_hash = filebase64sha256(local.lambda_packages.submit_cv)
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.main.address
      DB_PORT     = aws_db_instance.main.port
      DB_NAME     = aws_db_instance.main.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      S3_BUCKET   = aws_s3_bucket.cv_storage.bucket
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.submit_cv
  ]

  tags = local.common_tags
}

# Lambda function for listing applications
resource "aws_lambda_function" "list_applications" {
  filename         = local.lambda_packages.list_applications
  function_name    = "${local.name_prefix}-list-applications"
  role            = aws_iam_role.lambda.arn
  handler         = "list_applications.lambda_handler"
  source_code_hash = filebase64sha256(local.lambda_packages.list_applications)
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.main.address
      DB_PORT     = aws_db_instance.main.port
      DB_NAME     = aws_db_instance.main.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.list_applications
  ]

  tags = local.common_tags
}

# Lambda function for getting single application
resource "aws_lambda_function" "get_application" {
  filename         = local.lambda_packages.get_application
  function_name    = "${local.name_prefix}-get-application"
  role            = aws_iam_role.lambda.arn
  handler         = "get_application.lambda_handler"
  source_code_hash = filebase64sha256(local.lambda_packages.get_application)
  runtime         = "python3.9"
  timeout         = 30
  memory_size     = 256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.main.address
      DB_PORT     = aws_db_instance.main.port
      DB_NAME     = aws_db_instance.main.db_name
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      S3_BUCKET   = aws_s3_bucket.cv_storage.bucket
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.get_application
  ]

  tags = local.common_tags
}

# Use pre-built Lambda packages with dependencies
locals {
  lambda_packages = {
    submit_cv = "${path.module}/submit_cv.zip"
    list_applications = "${path.module}/list_applications.zip" 
    get_application = "${path.module}/get_application.zip"
    admin_login = "${path.module}/admin_login.zip"
  }
}
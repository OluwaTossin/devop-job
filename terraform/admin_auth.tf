# Admin credentials stored in AWS Secrets Manager
resource "aws_secretsmanager_secret" "admin_credentials" {
  name        = "${local.name_prefix}-admin-credentials"
  description = "Admin login credentials for DevOps Job Portal"

  tags = local.common_tags

  lifecycle {
    # If the secret already exists outside of state (e.g., from a previous run),
    # we will import it via CI before planning. Avoid accidental destroy/replace.
    prevent_destroy = true
    ignore_changes  = [name, description]
  }
}

resource "aws_secretsmanager_secret_version" "admin_credentials" {
  secret_id = aws_secretsmanager_secret.admin_credentials.id
  secret_string = jsonencode({
    username = var.admin_username
    # This is a SHA256 hash of the default password "admin123"
    # In production, use a stronger password and bcrypt hashing
    # Updated to match provided password: Admin123!@#
    password_hash = "a8d51fc6a058bfeacb77818d42d420ac1bf31529393a784ec60f7c2443047462"
    jwt_secret    = random_password.jwt_secret.result
  })
}

# Generate random JWT secret
resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# IAM role for admin login Lambda function
resource "aws_iam_role" "admin_login_lambda" {
  name = "${local.name_prefix}-admin-login-lambda"

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

# IAM policy for admin login Lambda function
resource "aws_iam_role_policy" "admin_login_lambda" {
  name = "${local.name_prefix}-admin-login-lambda"
  role = aws_iam_role.admin_login_lambda.id

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
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.admin_credentials.arn
      }
    ]
  })
}

# CloudWatch Log Group for admin login Lambda
resource "aws_cloudwatch_log_group" "admin_login" {
  name              = "/aws/lambda/${local.name_prefix}-admin-login"
  retention_in_days = 7 # Fixed to valid CloudWatch retention period

  tags = local.common_tags

  lifecycle {
    # Log groups may pre-exist if Lambda ran previously; avoid replacement
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

# Lambda function for admin login
resource "aws_lambda_function" "admin_login" {
  filename         = local.lambda_packages.admin_login
  function_name    = "${local.name_prefix}-admin-login"
  role             = aws_iam_role.admin_login_lambda.arn
  handler          = "admin_login.lambda_handler"
  source_code_hash = filebase64sha256(local.lambda_packages.admin_login)
  runtime          = "python3.9"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      ADMIN_CREDENTIALS_SECRET = aws_secretsmanager_secret.admin_credentials.name
      ENVIRONMENT              = var.environment
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.admin_login
  ]

  tags = local.common_tags
}
# Temporary Lambda function for database initialization
resource "aws_lambda_function" "init_database" {
  filename         = "${path.module}/init_database.zip"
  function_name    = "${local.name_prefix}-init-database"
  role            = aws_iam_role.lambda.arn
  handler         = "init_database.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/init_database.zip")
  runtime         = "python3.9"
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size

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
    }
  }

  tags = local.common_tags
}

# Package the init database function
data "archive_file" "init_database" {
  type        = "zip"
  source_file = "../backend/init_database.py"
  output_path = "init_database.zip"
}
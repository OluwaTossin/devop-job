# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.name_prefix}-api"
  description = "API Gateway for DevOps Job Portal"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

# API Gateway Resources
resource "aws_api_gateway_resource" "applications" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "applications"
}

resource "aws_api_gateway_resource" "application_id" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.applications.id
  path_part   = "{id}"
}

# CORS configuration
resource "aws_api_gateway_method" "applications_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.applications.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "applications_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.applications.id
  http_method = aws_api_gateway_method.applications_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "applications_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.applications.id
  http_method = aws_api_gateway_method.applications_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "applications_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.applications.id
  http_method = aws_api_gateway_method.applications_options.http_method
  status_code = aws_api_gateway_method_response.applications_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# POST /applications (Submit CV)
resource "aws_api_gateway_method" "submit_cv" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.applications.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "submit_cv" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.applications.id
  http_method = aws_api_gateway_method.submit_cv.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.submit_cv.invoke_arn
}

# GET /applications (List applications)
resource "aws_api_gateway_method" "list_applications" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.applications.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_applications" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.applications.id
  http_method = aws_api_gateway_method.list_applications.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_applications.invoke_arn
}

# GET /applications/{id} (Get single application)
resource "aws_api_gateway_method" "get_application" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.application_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_application" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.application_id.id
  http_method = aws_api_gateway_method.get_application.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_application.invoke_arn
}

# Admin resource for authentication endpoints
resource "aws_api_gateway_resource" "admin" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "admin"
}

resource "aws_api_gateway_resource" "admin_login" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.admin.id
  path_part   = "login"
}

# OPTIONS method for admin/login CORS
resource "aws_api_gateway_method" "admin_login_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.admin_login.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "admin_login_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.admin_login.id
  http_method = aws_api_gateway_method.admin_login_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "admin_login_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.admin_login.id
  http_method = aws_api_gateway_method.admin_login_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "admin_login_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.admin_login.id
  http_method = aws_api_gateway_method.admin_login_options.http_method
  status_code = aws_api_gateway_method_response.admin_login_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# POST /admin/login (Admin Login)
resource "aws_api_gateway_method" "admin_login" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.admin_login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "admin_login" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.admin_login.id
  http_method = aws_api_gateway_method.admin_login.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.admin_login.invoke_arn
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "submit_cv" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.submit_cv.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "list_applications" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_applications.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_application" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_application.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

resource "aws_lambda_permission" "admin_login" {
  statement_id  = "AllowExecutionFromAPIGateway-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.admin_login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.submit_cv,
    aws_api_gateway_method.list_applications,
    aws_api_gateway_method.get_application,
    aws_api_gateway_method.admin_login,
    aws_api_gateway_integration.submit_cv,
    aws_api_gateway_integration.list_applications,
    aws_api_gateway_integration.get_application,
    aws_api_gateway_integration.admin_login,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.applications.id,
      aws_api_gateway_resource.admin.id,
      aws_api_gateway_method.submit_cv.id,
      aws_api_gateway_method.list_applications.id,
      aws_api_gateway_method.get_application.id,
      aws_api_gateway_method.admin_login.id,
      aws_api_gateway_integration.submit_cv.id,
      aws_api_gateway_integration.list_applications.id,
      aws_api_gateway_integration.get_application.id,
      aws_api_gateway_integration.admin_login.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  depends_on = [aws_api_gateway_account.main]

  tags = local.common_tags
}

# IAM Role for API Gateway CloudWatch Logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.name_prefix}-api-gateway-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}

# Attach the managed policy for API Gateway to push to CloudWatch
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# Set the API Gateway account settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${local.name_prefix}"
  retention_in_days = var.environment == "prod" ? 14 : 7

  tags = local.common_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [name]
  }
}
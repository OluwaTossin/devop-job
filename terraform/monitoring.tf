# CloudWatch Alarms for Lambda functions

# Lambda Error Rate Alarm - Submit CV
resource "aws_cloudwatch_metric_alarm" "lambda_submit_cv_errors" {
  alarm_name          = "${local.name_prefix}-submit-cv-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors submit cv lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.submit_cv.function_name
  }

  tags = local.common_tags
}

# Lambda Duration Alarm - Submit CV
resource "aws_cloudwatch_metric_alarm" "lambda_submit_cv_duration" {
  alarm_name          = "${local.name_prefix}-submit-cv-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000"  # 25 seconds
  alarm_description   = "This metric monitors submit cv lambda duration"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.submit_cv.function_name
  }

  tags = local.common_tags
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = local.common_tags
}

# RDS Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = local.common_tags
}

# API Gateway 4xx Error Rate
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx" {
  alarm_name          = "${local.name_prefix}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors API Gateway 4xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName   = aws_api_gateway_rest_api.main.name
    Stage     = aws_api_gateway_stage.main.stage_name
  }

  tags = local.common_tags
}

# API Gateway 5xx Error Rate
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${local.name_prefix}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors API Gateway 5xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ApiName   = aws_api_gateway_rest_api.main.name
    Stage     = aws_api_gateway_stage.main.stage_name
  }

  tags = local.common_tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = local.common_tags
}

# Auto Scaling for Lambda (Provisioned Concurrency)
resource "aws_lambda_provisioned_concurrency_config" "submit_cv" {
  count                             = var.environment == "prod" ? 1 : 0
  function_name                     = aws_lambda_function.submit_cv.function_name
  provisioned_concurrent_executions = 2
  qualifier                         = aws_lambda_function.submit_cv.version
}

# Lambda function aliases for better versioning
resource "aws_lambda_alias" "submit_cv" {
  name             = var.environment
  description      = "${var.environment} environment alias"
  function_name    = aws_lambda_function.submit_cv.function_name
  function_version = aws_lambda_function.submit_cv.version
}

resource "aws_lambda_alias" "list_applications" {
  name             = var.environment
  description      = "${var.environment} environment alias"
  function_name    = aws_lambda_function.list_applications.function_name
  function_version = aws_lambda_function.list_applications.version
}

resource "aws_lambda_alias" "get_application" {
  name             = var.environment
  description      = "${var.environment} environment alias"
  function_name    = aws_lambda_function.get_application.function_name
  function_version = aws_lambda_function.get_application.version
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.submit_cv.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Lambda Metrics - Submit CV"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.main.id],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", aws_api_gateway_rest_api.main.name, "Stage", aws_api_gateway_stage.main.stage_name],
            [".", "Latency", ".", ".", ".", "."],
            [".", "4XXError", ".", ".", ".", "."],
            [".", "5XXError", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Metrics"
          view   = "timeSeries"
        }
      }
    ]
  })
}
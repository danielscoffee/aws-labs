terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = var.region
}

# ── IAM ───────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# X-Ray write access
resource "aws_iam_role_policy_attachment" "xray" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# ── Lambda (with X-Ray active tracing) ───────────────────────────────────────

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/.build/handler.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.prefix}-monitored"
  retention_in_days = 7
}

resource "aws_lambda_function" "monitored" {
  function_name    = "${var.prefix}-monitored"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  depends_on       = [aws_cloudwatch_log_group.lambda]

  # Active tracing → X-Ray
  tracing_config {
    mode = "Active"
  }
}

# ── CloudWatch: metric filter + alarm ────────────────────────────────────────

# Filter that counts ERROR lines in the Lambda log group
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.prefix}-error-count"
  pattern        = "ERROR"
  log_group_name = aws_cloudwatch_log_group.lambda.name

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "${var.prefix}/Lambda"
    value         = "1"
    default_value = "0"
  }
}

# SNS topic for alarm notifications
resource "aws_sns_topic" "alarms" {
  name = "${var.prefix}-alarms"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Alarm: fires when ≥3 errors in 5 minutes
resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.prefix}-high-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${var.prefix}/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Lambda error count >= 3 in 5 minutes"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]
}

# Built-in Lambda metric alarm: p99 duration > 1s
resource "aws_cloudwatch_metric_alarm" "duration_p99" {
  alarm_name          = "${var.prefix}-p99-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 1000 # ms
  alarm_description   = "p99 Lambda duration > 1 second"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    FunctionName = aws_lambda_function.monitored.function_name
  }
}

# ── X-Ray sampling rule ───────────────────────────────────────────────────────

resource "aws_xray_sampling_rule" "lab" {
  rule_name      = "${var.prefix}-sampling"
  priority       = 9000
  reservoir_size = 5
  fixed_rate     = 0.1 # sample 10% of requests after reservoir
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = aws_lambda_function.monitored.function_name
  resource_arn   = "*"
  version        = 1
}

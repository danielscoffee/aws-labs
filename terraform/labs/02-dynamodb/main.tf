terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = var.region
}

# ── DynamoDB table ─────────────────────────────────────────────────────────────

resource "aws_dynamodb_table" "orders" {
  name         = "${var.prefix}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }

  # GSI — query by status
  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "sk"
    projection_type = "ALL"
  }

  # Stream — feeds the Lambda below
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }
}

# ── IAM ───────────────────────────────────────────────────────────────────────

resource "aws_iam_role" "stream_lambda" {
  name = "${var.prefix}-stream-lambda-role"
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
  role       = aws_iam_role.stream_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "stream_read" {
  name = "dynamo-stream-read"
  role = aws_iam_role.stream_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeStream",
        "dynamodb:ListStreams",
      ]
      Resource = aws_dynamodb_table.orders.stream_arn
    }]
  })
}

# ── Lambda stream processor ───────────────────────────────────────────────────

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/.build/handler.zip"
}

resource "aws_cloudwatch_log_group" "stream_lambda" {
  name              = "/aws/lambda/${var.prefix}-stream-processor"
  retention_in_days = 7
}

resource "aws_lambda_function" "stream_processor" {
  function_name    = "${var.prefix}-stream-processor"
  role             = aws_iam_role.stream_lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  depends_on       = [aws_cloudwatch_log_group.stream_lambda]
}

# Event source mapping — DynamoDB Stream → Lambda
resource "aws_lambda_event_source_mapping" "dynamo_stream" {
  event_source_arn  = aws_dynamodb_table.orders.stream_arn
  function_name     = aws_lambda_function.stream_processor.arn
  starting_position = "LATEST"
  batch_size        = 10

  # bisect batch on error — exam topic
  bisect_batch_on_function_error = true
}

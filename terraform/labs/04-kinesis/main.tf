terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = var.region
}

# ── Kinesis Data Stream ───────────────────────────────────────────────────────

resource "aws_kinesis_stream" "events" {
  name             = "${var.prefix}-events"
  shard_count      = 1
  retention_period = 24 # hours

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

# ── S3 bucket (Firehose destination) ─────────────────────────────────────────

resource "aws_s3_bucket" "firehose_dest" {
  bucket        = "${var.prefix}-firehose-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

data "aws_caller_identity" "current" {}

# ── IAM for Firehose ─────────────────────────────────────────────────────────

resource "aws_iam_role" "firehose" {
  name = "${var.prefix}-firehose-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "firehose" {
  name = "firehose-policy"
  role = aws_iam_role.firehose.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetBucketLocation"]
        Resource = ["${aws_s3_bucket.firehose_dest.arn}", "${aws_s3_bucket.firehose_dest.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:DescribeStream", "kinesis:ListStreams"]
        Resource = aws_kinesis_stream.events.arn
      }
    ]
  })
}

# ── Kinesis Firehose → S3 ────────────────────────────────────────────────────

resource "aws_kinesis_firehose_delivery_stream" "to_s3" {
  name        = "${var.prefix}-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.events.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose.arn
    bucket_arn         = aws_s3_bucket.firehose_dest.arn
    buffering_size     = 5    # MB
    buffering_interval = 60   # seconds
    prefix             = "raw/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/"
  }
}

# ── Lambda consumer (standard — not enhanced fan-out) ─────────────────────────

resource "aws_iam_role" "consumer" {
  name = "${var.prefix}-consumer-role"
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
  role       = aws_iam_role.consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "kinesis_read" {
  name = "kinesis-read"
  role = aws_iam_role.consumer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kinesis:GetRecords", "kinesis:GetShardIterator", "kinesis:DescribeStream", "kinesis:ListStreams"]
      Resource = aws_kinesis_stream.events.arn
    }]
  })
}

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/.build/handler.zip"
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/aws/lambda/${var.prefix}-consumer"
  retention_in_days = 7
}

resource "aws_lambda_function" "consumer" {
  function_name    = "${var.prefix}-consumer"
  role             = aws_iam_role.consumer.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  depends_on       = [aws_cloudwatch_log_group.consumer]
}

resource "aws_lambda_event_source_mapping" "kinesis" {
  event_source_arn  = aws_kinesis_stream.events.arn
  function_name     = aws_lambda_function.consumer.arn
  starting_position = "LATEST"
  batch_size        = 100
}

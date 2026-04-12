terraform {
  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 6.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.0" }
  }
}

provider "aws" {
  region = var.region
}

# ── SNS topic ─────────────────────────────────────────────────────────────────

resource "aws_sns_topic" "events" {
  name = "${var.prefix}-events"
}

# ── SQS queues (fan-out pattern) ──────────────────────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.prefix}-dlq"
  message_retention_seconds = 1209600 # 14 days max
}

resource "aws_sqs_queue" "main" {
  name                       = "${var.prefix}-main"
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 20 # long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# Allow SNS to send messages to the queue
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.main.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.events.arn }
      }
    }]
  })
}

# SNS → SQS subscription (fan-out)
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn

  # filter policy example — only messages with type=order reach this queue
  filter_policy = jsonencode({
    type = ["order"]
  })
}

# ── IAM ───────────────────────────────────────────────────────────────────────

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

resource "aws_iam_role_policy" "sqs_consume" {
  name = "sqs-consume"
  role = aws_iam_role.consumer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
      Resource = aws_sqs_queue.main.arn
    }]
  })
}

# ── Lambda consumer ───────────────────────────────────────────────────────────

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

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.consumer.arn
  batch_size       = 5
}

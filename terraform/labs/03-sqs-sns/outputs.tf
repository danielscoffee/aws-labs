output "sns_topic_arn" {
  value = aws_sns_topic.events.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.main.url
}

output "dlq_url" {
  value = aws_sqs_queue.dlq.url
}

output "consumer_lambda" {
  value = aws_lambda_function.consumer.function_name
}

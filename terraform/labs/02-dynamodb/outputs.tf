output "table_name" {
  value = aws_dynamodb_table.orders.name
}

output "gsi_name" {
  value = "status-index"
}

output "stream_arn" {
  value = aws_dynamodb_table.orders.stream_arn
}

output "stream_processor" {
  value = aws_lambda_function.stream_processor.function_name
}

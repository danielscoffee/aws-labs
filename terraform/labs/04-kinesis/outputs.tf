output "stream_name" {
  value = aws_kinesis_stream.events.name
}

output "stream_arn" {
  value = aws_kinesis_stream.events.arn
}

output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.to_s3.name
}

output "s3_bucket" {
  value = aws_s3_bucket.firehose_dest.bucket
}

output "consumer_lambda" {
  value = aws_lambda_function.consumer.function_name
}

output "lambda_name" {
  value = aws_lambda_function.monitored.function_name
}

output "log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "alarm_error_rate" {
  value = aws_cloudwatch_metric_alarm.error_rate.alarm_name
}

output "alarm_duration_p99" {
  value = aws_cloudwatch_metric_alarm.duration_p99.alarm_name
}

output "sns_alarm_topic" {
  value = aws_sns_topic.alarms.arn
}

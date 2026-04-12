output "api_url" {
  description = "Base URL — curl this to test the integration"
  value       = "${aws_api_gateway_stage.dev.invoke_url}/hello"
}

output "lambda_name" {
  value = aws_lambda_function.api.function_name
}

output "log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}

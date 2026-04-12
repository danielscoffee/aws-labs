output "user_pool_id" {
  value = aws_cognito_user_pool.main.id
}

output "user_pool_endpoint" {
  value = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  value = aws_cognito_user_pool_client.app.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.main.id
}

output "authenticated_role_arn" {
  value = aws_iam_role.authenticated.arn
}

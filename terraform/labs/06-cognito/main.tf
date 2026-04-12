terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = var.region
}

# ── User Pool ─────────────────────────────────────────────────────────────────

resource "aws_cognito_user_pool" "main" {
  name = "${var.prefix}-users"

  # Allow sign-in with email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Token validity
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }
}

# App client — used by your frontend / CLI to authenticate
resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.prefix}-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false # public client (SPA / mobile)

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  # Token validity (exam: difference between ID / Access / Refresh tokens)
  access_token_validity  = 60   # minutes
  id_token_validity      = 60   # minutes
  refresh_token_validity = 30   # days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# ── Identity Pool ─────────────────────────────────────────────────────────────
# Exchanges Cognito JWT for temporary AWS credentials via STS

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${var.prefix} identity pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.app.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = false
  }
}

# IAM role for authenticated users
resource "aws_iam_role" "authenticated" {
  name = "${var.prefix}-cognito-authenticated"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = "cognito-identity.amazonaws.com" }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
        }
        "ForAnyValue:StringLike" = {
          "cognito-identity.amazonaws.com:amr" = "authenticated"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "authenticated" {
  name = "cognito-authenticated-policy"
  role = aws_iam_role.authenticated.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.prefix}-user-files/*"
    }]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id
  roles = {
    authenticated = aws_iam_role.authenticated.arn
  }
}

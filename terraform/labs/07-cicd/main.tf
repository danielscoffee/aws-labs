terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "source" {
  bucket        = "${var.prefix}-source-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.prefix}-artifacts-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "buildspec" {
  bucket = aws_s3_bucket.source.id
  key    = "buildspec.yml"
  source = "${path.module}/buildspec.yml"
  etag   = filemd5("${path.module}/buildspec.yml")
}

resource "aws_iam_role" "codebuild" {
  name = "${var.prefix}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.source.arn}/*", "${aws_s3_bucket.artifacts.arn}/*"]
      }
    ]
  })
}

resource "aws_codebuild_project" "app" {
  name          = "${var.prefix}-build"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 10

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.source.bucket}/buildspec.yml"
    buildspec = "buildspec.yml"
  }

  artifacts {
    type                = "S3"
    location            = aws_s3_bucket.artifacts.bucket
    name                = "artifact.zip"
    packaging           = "ZIP"
    encryption_disabled = true
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = false

    environment_variable {
      name  = "ENV"
      value = var.prefix
    }
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifacts.bucket}/cache"
  }
}

# ── IAM for CodePipeline ──────────────────────────────────────────────────────

resource "aws_iam_role" "pipeline" {
  name = "${var.prefix}-pipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pipeline" {
  name = "pipeline-policy"
  role = aws_iam_role.pipeline.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:GetBucketVersioning"]
        Resource = ["${aws_s3_bucket.source.arn}/*", "${aws_s3_bucket.artifacts.arn}/*", aws_s3_bucket.source.arn, aws_s3_bucket.artifacts.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["codebuild:BatchGetBuilds", "codebuild:StartBuild"]
        Resource = aws_codebuild_project.app.arn
      }
    ]
  })
}

# ── CodePipeline: Source (S3) → Build (CodeBuild) ────────────────────────────

resource "aws_codepipeline" "main" {
  name     = "${var.prefix}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "S3Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        S3Bucket             = aws_s3_bucket.source.bucket
        S3ObjectKey          = "buildspec.yml"
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }
}

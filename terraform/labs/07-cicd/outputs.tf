output "source_bucket" {
  value = aws_s3_bucket.source.bucket
}

output "artifacts_bucket" {
  value = aws_s3_bucket.artifacts.bucket
}

output "codebuild_project" {
  value = aws_codebuild_project.app.name
}

output "pipeline_name" {
  value = aws_codepipeline.main.name
}

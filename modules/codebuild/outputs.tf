output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.runner.name
}

output "codebuild_iam_role_arn" {
  description = "CodeBuild IAM role ARN"
  value       = aws_iam_role.runner.arn
}

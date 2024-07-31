output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.runner.name
}

output "codebuild_iam_role_arn" {
  description = "CodeBuild IAM role ARN"
  value       = aws_iam_role.runner.arn
}

output "codebuild_cloudwatch_logs_log_group_name" {
  description = "CodeBuild CloudWatch Logs log group name"
  value       = length(aws_cloudwatch_log_group.runner) > 0 ? aws_cloudwatch_log_group.runner[0].name : null
}

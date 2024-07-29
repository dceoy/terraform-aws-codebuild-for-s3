output "codebuild_project_names" {
  description = "CodeBuild project names"
  value       = { for k, v in aws_codebuild_project.github : k => v.name }
}

output "codebuild_webhook_ids" {
  description = "CodeBuild webhook IDs"
  value       = { for k, v in aws_codebuild_webhook.github : k => v.id }
}

output "codebuild_cloudwatch_logs_log_group_name" {
  description = "CodeBuild CloudWatch Logs log group name"
  value       = aws_cloudwatch_log_group.github.name
}

output "codebuild_execution_iam_role_arn" {
  description = "CodeBuild execution IAM role ARN"
  value       = aws_iam_role.github.arn
}

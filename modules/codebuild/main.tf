resource "aws_codebuild_project" "runner" {
  name         = local.codebuild_project_name
  description  = "CodeBuild project using buildspec on S3"
  service_role = aws_iam_role.runner.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    type      = "NO_SOURCE"
    buildspec = <<-EOT
    ---
    version: 0.2
    phases:
      dummy:
        commands:
          - echo 'This buildspec will be overridden.'
    EOT
  }
  environment {
    type                        = var.codebuild_environment_type
    compute_type                = var.codebuild_environment_compute_type
    image                       = var.codebuild_environment_image
    image_pull_credentials_type = var.codebuild_environment_image_pull_credentials_type
    privileged_mode             = var.codebuild_environment_privileged_mode
  }
  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }
    dynamic "s3_logs" {
      for_each = var.codebuild_logs_config_s3_bucket_id != null ? [true] : []
      content {
        location = "${var.codebuild_logs_config_s3_logs_bucket_id}/${var.system_name}/${var.env_type}/codebuild/${local.codebuild_project_name}"
        status   = "ENABLED"
      }
    }
  }
  build_timeout  = var.codebuild_build_timeout
  queued_timeout = var.codebuild_queued_timeout
  tags = {
    Name       = local.codebuild_project_name
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_iam_role" "runner" {
  name                  = "${var.system_name}-${var.env_type}-s3-codebuild-iam-role"
  description           = "CodeBuild service IAM role for S3 access"
  force_detach_policies = var.iam_role_force_detach_policies
  path                  = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeBuildServiceToAssumeRole"
        Effect = "Allow"
        Action = ["sts:AssumeRole"]
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = compact(var.codebuild_iam_policy_arns)
  tags = {
    Name       = "${var.system_name}-${var.env_type}-s3-codebuild-iam-role"
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

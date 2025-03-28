resource "aws_codebuild_project" "runner" {
  name           = local.codebuild_project_name
  description    = "CodeBuild project using buildspec"
  service_role   = aws_iam_role.runner.arn
  build_timeout  = var.codebuild_build_timeout
  queued_timeout = var.codebuild_queued_timeout
  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file(var.codebuild_buildspec_yml_path)
  }
  environment {
    type                        = var.codebuild_environment_type
    compute_type                = var.codebuild_environment_compute_type
    image                       = var.codebuild_environment_image
    image_pull_credentials_type = var.codebuild_environment_image_pull_credentials_type
    privileged_mode             = var.codebuild_environment_privileged_mode
    dynamic "environment_variable" {
      for_each = var.codebuild_environment_environment_variables
      content {
        name  = environment_variable.key
        value = environment_variable.value
        type  = "PLAINTEXT"
      }
    }
  }
  logs_config {
    cloudwatch_logs {
      status     = length(aws_cloudwatch_log_group.runner) > 0 ? "ENABLED" : "DISABLED"
      group_name = length(aws_cloudwatch_log_group.runner) > 0 ? aws_cloudwatch_log_group.runner[0].name : null
      # stream_name = null
    }
    dynamic "s3_logs" {
      for_each = length(aws_cloudwatch_log_group.runner) == 0 && var.codebuild_logs_config_s3_logs_bucket_id != null ? [true] : []
      content {
        status              = "ENABLED"
        location            = "${var.codebuild_logs_config_s3_logs_bucket_id}/${var.system_name}/${var.env_type}/codebuild/${local.codebuild_project_name}"
        encryption_disabled = false
      }
    }
  }
  dynamic "vpc_config" {
    for_each = length(aws_iam_role_policy.vpc) > 0 ? [true] : []
    content {
      vpc_id             = var.codebuild_vpc_config_vpc_id
      subnets            = var.codebuild_vpc_config_subnets
      security_group_ids = var.codebuild_vpc_config_security_group_ids
    }
  }
  tags = {
    Name       = local.codebuild_project_name
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_iam_role" "runner" {
  name                  = "${var.system_name}-${var.env_type}-codebuild-iam-role"
  description           = "CodeBuild service IAM role"
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
  tags = {
    Name       = "${var.system_name}-${var.env_type}-codebuild-iam-role"
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_iam_role_policy_attachments_exclusive" "runner" {
  count       = length(var.codebuild_iam_policy_arns) > 0 ? 1 : 0
  role_name   = aws_iam_role.runner.name
  policy_arns = var.codebuild_iam_policy_arns
}

resource "aws_iam_role_policy" "vpc" {
  count = var.codebuild_vpc_config_vpc_id != null && length(var.codebuild_vpc_config_subnets) > 0 && length(var.codebuild_vpc_config_security_group_ids) > 0 ? 1 : 0
  name  = "${var.system_name}-${var.env_type}-codebuild-vpc-iam-policy"
  role  = aws_iam_role.runner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowENIPermission"
        Effect   = "Allow"
        Action   = ["ec2:CreateNetworkInterfacePermission"]
        Resource = ["arn:aws:ec2:${local.region}:${local.account_id}:network-interface/*"]
        Condition = {
          StringEquals = {
            "ec2:AuthorizedService" = "codebuild.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "runner" {
  count             = var.enable_cloudwatch_logs ? 1 : 0
  name              = "/${var.system_name}/${var.env_type}/codebuild/${local.codebuild_project_name}"
  retention_in_days = var.cloudwatch_logs_retention_in_days
  kms_key_id        = var.kms_key_arn
  tags = {
    Name       = "/${var.system_name}/${var.env_type}/codebuild/${local.codebuild_project_name}"
    SystemName = var.system_name
    EnvType    = var.env_type
  }
}

resource "aws_iam_role_policy" "logs" {
  count = length(aws_cloudwatch_log_group.runner) > 0 ? 1 : 0
  name  = "${var.system_name}-${var.env_type}-cloudwatch-logs-policy"
  role  = aws_iam_role.runner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "AllowDescribeLogGroups"
          Effect   = "Allow"
          Action   = ["logs:DescribeLogGroups"]
          Resource = ["arn:aws:logs:${local.region}:${local.account_id}:log-group:*"]
        },
        {
          Sid    = "AllowLogStreamAccess"
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = ["${aws_cloudwatch_log_group.runner[count.index].arn}:*"]
        }
      ],
      (
        var.kms_key_arn != null ? [
          {
            Sid      = "AllowKMSAccess"
            Effect   = "Allow"
            Action   = ["kms:GenerateDataKey"]
            Resource = [var.kms_key_arn]
          }
        ] : []
      )
    )
  })
}

variable "system_name" {
  description = "System name"
  type        = string
  default     = "cfs"
}

variable "env_type" {
  description = "Environment type"
  type        = string
  default     = "dev"
}

variable "kms_key_arn" {
  description = "KMS key ARN"
  type        = string
  default     = null
}

variable "cloudwatch_logs_retention_in_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_logs_retention_in_days)
    error_message = "CloudWatch Logs retention in days must be 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 or 0 (zero indicates never expire logs)"
  }
}

variable "iam_role_force_detach_policies" {
  description = "Whether to force detaching any IAM policies the IAM role has before destroying it"
  type        = bool
  default     = true
}

variable "codebuild_environment_type" {
  description = "CodeBuild environment type"
  type        = string
  default     = "ARM_CONTAINER"
}

variable "codebuild_environment_compute_type" {
  description = "Compute type for CodeBuild environment"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_environment_image" {
  description = "Image for CodeBuild environment"
  type        = string
  default     = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
}

variable "codebuild_environment_image_pull_credentials_type" {
  description = "Type of image pull credentials to use for CodeBuild environment"
  type        = string
  default     = "CODEBUILD"
}

variable "codebuild_environment_privileged_mode" {
  description = "Whether to enable privileged mode for CodeBuild environment"
  type        = bool
  default     = false
}

variable "codebuild_build_timeout" {
  description = "Build timeout for CodeBuild project"
  type        = number
  default     = 5
  validation {
    condition     = var.codebuild_build_timeout >= 5 && var.codebuild_build_timeout <= 480
    error_message = "CodeBuild build timeout must be between 5 and 480 minutes"
  }
}

variable "codebuild_queued_timeout" {
  description = "Queued timeout for CodeBuild project"
  type        = number
  default     = 5
  validation {
    condition     = var.codebuild_queued_timeout >= 5 && var.codebuild_queued_timeout <= 480
    error_message = "CodeBuild queued timeout must be between 5 and 480 minutes"
  }
}

variable "codebuild_logs_config_s3_logs_bucket_id" {
  description = "S3 bucket ID for CodeBuild logs"
  type        = string
  default     = null
}

variable "codebuild_iam_policy_arns" {
  description = "IAM policy ARNs to attach to CodeBuild IAM role"
  type        = list(string)
  default     = []
}

variable "enable_cloudwatch_logs" {
  description = "Whether to enable CloudWatch logs for CodeBuild project"
  type        = bool
  default     = false
}

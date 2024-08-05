locals {
  repo_root = get_repo_root()
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  extra_arguments "parallelism" {
    commands = get_terraform_commands_that_need_parallelism()
    arguments = [
      "-parallelism=2"
    ]
  }
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.env_vars.locals.terraform_s3_bucket
    key            = "${basename(local.repo_root)}/${local.env_vars.locals.system_name}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.env_vars.locals.region
    encrypt        = true
    dynamodb_table = local.env_vars.locals.terraform_dynamodb_table
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.env_vars.locals.region}"
  default_tags {
    tags = {
      SystemName = "${local.env_vars.locals.system_name}"
      EnvType    = "${local.env_vars.locals.env_type}"
    }
  }
}
EOF
}

catalog {
  urls = [
    "${local.repo_root}/modules/kms",
    "${local.repo_root}/modules/s3",
    "${local.repo_root}/modules/codebuild"
  ]
}

inputs = {
  system_name                                       = local.env_vars.locals.system_name
  env_type                                          = local.env_vars.locals.env_type
  create_kms_key                                    = false
  kms_key_deletion_window_in_days                   = 30
  kms_key_rotation_period_in_days                   = 365
  s3_force_destroy                                  = true
  s3_noncurrent_version_expiration_days             = 7
  s3_abort_incomplete_multipart_upload_days         = 7
  s3_expired_object_delete_marker                   = true
  enable_s3_server_access_logging                   = true
  iam_role_force_detach_policies                    = true
  codebuild_buildspec_yml_path                      = find_in_parent_folders("buildspec.yml")
  codebuild_environment_type                        = "ARM_CONTAINER"
  codebuild_environment_compute_type                = "BUILD_GENERAL1_SMALL"
  codebuild_environment_image                       = "aws/codebuild/amazonlinux2-aarch64-standard:3.0"
  codebuild_environment_image_pull_credentials_type = "CODEBUILD"
  codebuild_environment_privileged_mode             = false
  codebuild_environment_environment_variables = {
    "SYSTEM_NAME"        = local.env_vars.locals.system_name
    "ENV_TYPE"           = local.env_vars.locals.env_type
    "AWS_ACCOUNT_ID"     = local.env_vars.locals.account_id
    "AWS_DEFAULT_REGION" = local.env_vars.locals.region
  }
  codebuild_build_timeout           = 5
  codebuild_queue_timeout           = 5
  enable_cloudwatch_logs            = true
  cloudwatch_logs_retention_in_days = 30
}

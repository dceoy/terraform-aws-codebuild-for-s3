include "root" {
  path   = find_in_parent_folders()
  expose = true
}

dependency "kms" {
  config_path = "../kms"
  mock_outputs = {
    kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "s3" {
  config_path = "../s3"
  mock_outputs = {
    io_s3_bucket_id   = "mock-s3-io-s3-bucket-id"
    s3_iam_policy_arn = "arn:aws:iam::123456789012:policy/mock-s3-iam-policy-arn"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  kms_key_arn                             = include.root.inputs.create_kms_key ? dependency.kms.outputs.kms_key_arn : null
  codebuild_logs_config_s3_logs_bucket_id = dependency.s3.outputs.io_s3_bucket_id
  codebuild_iam_policy_arns = [
    dependency.s3.outputs.s3_iam_policy_arn,
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
}

terraform {
  source = "${get_repo_root()}/modules/codebuild"
}

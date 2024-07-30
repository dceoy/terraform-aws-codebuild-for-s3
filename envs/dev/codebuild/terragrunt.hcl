include "root" {
  path = find_in_parent_folders()
}

dependency "s3" {
  config_path = "../s3"
  mock_outputs = {
    s3_base_s3_bucket_id = "mock-s3-base-s3-bucket-id"
    s3_iam_policy_arn    = "arn:aws:iam::123456789012:policy/mock-s3-iam-policy-arn"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  codebuild_logs_config_s3_logs_bucket_id = dependency.s3.outputs.s3_base_s3_bucket_id
  codebuild_iam_policy_arns               = [dependency.s3.outputs.s3_iam_policy_arn]
}

terraform {
  source = "${get_repo_root()}/modules/codebuild"
}

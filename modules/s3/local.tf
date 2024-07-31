data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id         = data.aws_caller_identity.current.account_id
  region             = data.aws_region.current.name
  io_s3_bucket_name  = "${var.system_name}-${var.env_type}-io-${local.region}-${local.account_id}"
  log_s3_bucket_name = "${var.system_name}-${var.env_type}-log-${local.region}-${local.account_id}"
}

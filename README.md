terraform-aws-codebuild-for-s3
==============================

Terraform modules of a CodeBuild project for S3 buckets

[![CI](https://github.com/dceoy/terraform-aws-codebuild-for-s3/actions/workflows/ci.yml/badge.svg)](https://github.com/dceoy/terraform-aws-codebuild-for-s3/actions/workflows/ci.yml)

Installation
------------

1.  Check out the repository.

    ```sh
    $ git clone https://github.com/dceoy/terraform-aws-codebuild-for-s3.git
    $ cd terraform-aws-codebuild-for-s3
    ````

2.  Install [AWS CLI](https://aws.amazon.com/cli/) and set `~/.aws/config` and `~/.aws/credentials`.

3.  Install [Terraform](https://www.terraform.io/) and [Terragrunt](https://terragrunt.gruntwork.io/).

4.  Initialize Terraform working directories.

    ```sh
    $ terragrunt run-all init --terragrunt-working-dir='envs/dev/' -upgrade -reconfigure
    ```

5.  Generates a speculative execution plan. (Optional)

    ```sh
    $ terragrunt run-all plan --terragrunt-working-dir='envs/dev/'
    ```

6.  Creates or updates infrastructure.

    ```sh
    $ terragrunt run-all apply --terragrunt-working-dir='envs/dev/' --terragrunt-non-interactive
    ```

Usage
-----

```sh
$ aws codebuild start-build \
    --project-name slc-dev-s3-codebuild-project \
    --buildspec-override file://envs/buildspec.yml
```

Cleanup
-------

```sh
$ terragrunt run-all destroy --terragrunt-working-dir='envs/dev/' --terragrunt-non-interactive
```

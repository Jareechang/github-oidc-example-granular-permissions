# main.tf
provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

resource "aws_s3_bucket" "this" {
  bucket = "example-bucket-2711az"
  acl    = "private"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  client_id_list  = var.client_id_list
  thumbprint_list = ["a031c46782e6e6c662c2c87c76da9aa62ccabd8e"]
  url             = "https://token.actions.githubusercontent.com"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "github_actions_assume_role_policy_write_only" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
        format(
          "arn:aws:iam::%s:root",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        format(
          "arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repo_name}:ref:refs/heads/master"]
    }
  }
}

data "aws_iam_policy_document" "github_actions_assume_role_policy_read_only" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [
        format(
          "arn:aws:iam::%s:root",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        format(
          "arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
          data.aws_caller_identity.current.account_id
        )
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repo_name}:pull_request"]
    }
  }
}

resource "aws_iam_role" "github_actions_write_only" {
  name               = "github-actions-write-only"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_write_only.json
}

resource "aws_iam_role" "github_actions_read_only" {
  name               = "github-actions-read-only"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_policy_read_only.json
}

data "aws_iam_policy_document" "github_actions_read_only" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "github_actions_write_only" {
  statement {
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_read_only" {
  name   = "github-actions-read-only"
  role   = aws_iam_role.github_actions_read_only.id
  policy = data.aws_iam_policy_document.github_actions_read_only.json
}

resource "aws_iam_role_policy" "github_actions_write_only" {
  name   = "github-actions-write-only"
  role   = aws_iam_role.github_actions_write_only.id
  policy = data.aws_iam_policy_document.github_actions_write_only.json
}

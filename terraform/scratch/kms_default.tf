resource "aws_kms_key" "default" {
  count                   = var.encrypt_at_rest ? 1 : 0
  description             = "KMS key for at rest encryption"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_default[0].json
}

data "aws_iam_policy_document" "kms_default" {
  count = var.encrypt_at_rest ? 1 : 0

  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid = "Allow use of the key"
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:role/aws-elasticbeanstalk-ec2-role",
        "arn:aws:iam::${local.account_id}:role/aws-elasticbeanstalk-service-role"
      ]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
  statement {
    sid = "Allow attachment of persistent resources"
    principals {
      type        = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:role/aws-elasticbeanstalk-ec2-role",
        "arn:aws:iam::${local.account_id}:role/aws-elasticbeanstalk-service-role"
      ]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

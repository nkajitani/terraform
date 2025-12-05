data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "web" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.web.arn,
        aws_iam_role.rds_s3_access.arn,
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.web.arn}/*",
    ]
  }
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.web.arn,
      ]
    }
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.web.arn,
    ]
  }
  statement {
    sid    = "AllowALBLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.web.arn}/alb-access-logs/*",
      "${aws_s3_bucket.web.arn}/alb-connection-logs/*",
    ]
  }
}

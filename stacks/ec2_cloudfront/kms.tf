resource "aws_kms_key" "s3" {
  description             = "${var.project_name}-s3-kms-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  rotation_period_in_days = 90
  policy                  = data.aws_iam_policy_document.kms.json

  tags = {
    Name = "${var.project_name}-s3-kms-key"
  }
}

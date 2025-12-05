resource "aws_iam_role" "web" {
  name        = "${var.project_name}-web-role"
  description = "IAM role for web server instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-web-role"
  }
}

resource "aws_iam_role_policy_attachment" "web" {
  for_each = toset(local.web_policies)

  role       = aws_iam_role.web.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-instance-profile"
  role = aws_iam_role.web.name
}

resource "aws_iam_policy" "rds_s3_access" {
  name        = "${var.project_name}-rds-s3-access-policy"
  description = "IAM policy for RDS to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = "arn:aws:rds-db:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:dbuser:*/${var.aurora_username}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "rds_s3_access" {
  name        = "${var.project_name}-rds-s3-access-role"
  description = "IAM role for RDS to access S3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-rds-s3-access-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_s3_access" {
  role       = aws_iam_role.rds_s3_access.name
  policy_arn = aws_iam_policy.rds_s3_access.arn
}

resource "aws_iam_role" "rds_monitoring" {
  name        = "${var.project_name}-rds-monitoring-role"
  description = "IAM role for RDS enhanced monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }

}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_s3_bucket_policy" "web" {
  bucket = aws_s3_bucket.web.id
  policy = data.aws_iam_policy_document.web.json
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-aurora-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${var.project_name}-aurora-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.project_name}-aurora-cluster-parameter-group"
  family      = "aurora-mysql8.0"
  description = "Custom parameter group for Aurora MySQL 8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  tags = {
    Name = "${var.project_name}-aurora-mysql-cluster-params"
  }
}

resource "aws_db_parameter_group" "aurora" {
  name        = "${var.project_name}-aurora-mysql-instance-parameter-group"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL instance parameter group"

  parameter {
    name  = "max_connections"
    value = "150"
  }
  # output log in instance
  parameter {
    name  = "general_log"
    value = "1"
  }

  tags = {
    Name = "${var.project_name}-aurora-mysql-instance-params"
  }
}

resource "aws_rds_cluster" "aurora" {
  backtrack_window                = 1800
  cluster_identifier_prefix       = "${var.project_name}-aurora-cluster-"
  cluster_scalability_type        = "standard"
  database_insights_mode          = "standard"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  # output log to cloudwatch
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  engine_mode                     = "provisioned"
  engine_version                  = var.aurora_version
  engine                          = var.aurora_engine
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  master_password                 = var.aurora_password
  master_username                 = var.aurora_username
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  final_snapshot_identifier       = "${var.project_name}-aurora-final-snapshot"
  skip_final_snapshot             = false
  vpc_security_group_ids          = [aws_security_group.rds.id]
  iam_roles                       = [aws_iam_role.rds_s3_access.arn]

  tags = {
    Name = "${var.project_name}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count                   = 2
  db_parameter_group_name = aws_db_parameter_group.aurora.name
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  engine_version          = var.aurora_version
  engine                  = var.aurora_engine
  identifier_prefix       = "${var.project_name}-aurora-instance-"
  instance_class          = var.aurora_instance_class
  cluster_identifier      = aws_rds_cluster.aurora.id
  monitoring_interval     = 60
  monitoring_role_arn     = aws_iam_role.rds_monitoring.arn
  publicly_accessible     = false

  tags = {
    Name = "${var.project_name}-aurora-instance"
  }
}

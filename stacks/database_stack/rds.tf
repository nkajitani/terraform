resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-rds-subnet-group"
  subnet_ids = [for s in aws_subnet.rds : s.id]

  tags = {
    Name = "${var.project_name}-rds-subnet-group"
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  name        = "${var.project_name}-aurora-parameter-group"
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
    name  = "character_set_connection"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }
  parameter {
    name  = "character_set_results"
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
  name        = "${var.project_name}-aurora-mysql8-instance"
  family      = "aurora-mysql8.0"
  description = "Aurora MySQL instance parameter group"

  parameter {
    name  = "max_connections"
    value = "200"
  }
  parameter {
    name  = "general_log"
    value = "1"
  }

  tags = {
    Name = "${var.project_name}-aurora-mysql-instance-params"
  }
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.project_name}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_version                  = "8.0.mysql_aurora.3.10.1"
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.rds.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora.name
  backup_retention_period         = 7
  preferred_backup_window         = "07:00-09:00"
  preferred_maintenance_window    = "sun:10:00-sun:10:30"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  skip_final_snapshot             = true
  final_snapshot_identifier       = "${var.project_name}-aurora-cluster-final-snapshot"
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn
  backtrack_window                = 24
  copy_tags_to_snapshot           = true
  database_name                   = var.aurora_name
  master_username                 = var.aurora_username
  master_password                 = var.aurora_password

  tags = {
    Name = "${var.project_name}-aurora-cluster"
  }
}

resource "aws_rds_cluster_instance" "aurora" {
  count                   = var.aurora_instance_count
  identifier_prefix       = "${var.project_name}-aurora-instance-"
  cluster_identifier      = aws_rds_cluster.aurora.id
  instance_class          = var.aurora_instance_class
  engine                  = aws_rds_cluster.aurora.engine
  engine_version          = aws_rds_cluster.aurora.engine_version
  db_parameter_group_name = aws_db_parameter_group.aurora.name
  db_subnet_group_name    = aws_db_subnet_group.aurora.name
  publicly_accessible     = false
  monitoring_interval     = 60
  monitoring_role_arn     = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "${var.project_name}-aurora-instance"
  }
}
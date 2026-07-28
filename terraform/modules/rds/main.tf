############################################
# RDS module - data tier
# Standard RDS PostgreSQL, Single-AZ
# by default, in the private DB subnets.

############################################

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.db_subnet_ids
  tags       = var.tags
}

resource "random_password" "master" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.name_prefix}-db-credentials"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    dbname   = var.database_name
    host     = aws_db_instance.this.address
    port     = 5432
  })
}

resource "aws_kms_key" "rds" {
  description         = "KMS key for BluePeak RDS storage encryption"
  enable_key_rotation = true
  tags                = var.tags
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-postgres"
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage # enables storage autoscaling as data grows
  storage_type          = "gp2"                     # Free Tier covers gp2, not gp3
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  multi_az = var.multi_az # Free Tier only covers Single-AZ; set true once off Free Plan for real HA

  backup_retention_period      = var.backup_retention_days
  backup_window                = "03:00-04:00"
  maintenance_window            = "sun:04:30-sun:05:30"
  deletion_protection           = var.deletion_protection
  skip_final_snapshot           = !var.deletion_protection
  final_snapshot_identifier     = var.deletion_protection ? "${var.name_prefix}-final-snapshot" : null
  copy_tags_to_snapshot         = true
  apply_immediately             = var.apply_immediately
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  tags = var.tags
}

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.name_prefix}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

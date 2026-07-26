############################################
# RDS module - data tier
# Aurora MySQL, Serverless v2 for automatic
# capacity scaling with demand; Multi-AZ for HA
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
    host     = aws_rds_cluster.this.endpoint
    port     = 3306
  })
}

resource "aws_kms_key" "rds" {
  description         = "KMS key for BluePeak RDS storage encryption"
  enable_key_rotation = true
  tags                = var.tags
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.name_prefix}-aurora"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned"
  engine_version          = var.engine_version
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = random_password.master.result
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]

  storage_encrypted              = true
  kms_key_id                     = aws_kms_key.rds.arn
  backup_retention_period         = var.backup_retention_days
  preferred_backup_window          = "03:00-04:00"
  preferred_maintenance_window      = "sun:04:30-sun:05:30"
  deletion_protection              = var.deletion_protection
  skip_final_snapshot              = !var.deletion_protection
  final_snapshot_identifier        = var.deletion_protection ? "${var.name_prefix}-final-snapshot" : null
  copy_tags_to_snapshot            = true
  apply_immediately                = var.apply_immediately
  enabled_cloudwatch_logs_exports  = ["audit", "error", "slowquery"]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_acu
    max_capacity = var.max_acu
  }

  tags = var.tags
}

# Two instances across AZs -> HA / automated failover for a Serverless v2 cluster
resource "aws_rds_cluster_instance" "this" {
  count                = var.instance_count
  identifier           = "${var.name_prefix}-aurora-${count.index}"
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  db_subnet_group_name = aws_db_subnet_group.this.name

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  tags = var.tags
}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.name_prefix}-rds-monitoring-role"
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
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

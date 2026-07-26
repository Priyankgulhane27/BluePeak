output "cluster_endpoint" { value = aws_rds_cluster.this.endpoint }
output "reader_endpoint" { value = aws_rds_cluster.this.reader_endpoint }
output "secret_arn" { value = aws_secretsmanager_secret.db_credentials.arn }
output "cluster_id" { value = aws_rds_cluster.this.id }

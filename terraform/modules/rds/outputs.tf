output "instance_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "instance_address" {
  value = aws_db_instance.this.address
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "instance_id" {
  value = aws_db_instance.this.identifier
}

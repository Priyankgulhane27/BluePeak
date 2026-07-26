output "app_url" {
  value       = "http://${module.alb.alb_dns_name}"
  description = "Public URL for the counter app (HTTP unless certificate_arn is set)"
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "rds_cluster_endpoint" {
  value     = module.rds.cluster_endpoint
  sensitive = true
}

output "cloudwatch_dashboard" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}"
}

output "sns_alerts_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

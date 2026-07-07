output "alb_dns_name" {
  description = "Public URL of the deployed app (http://<this>/health)"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "Push images here from CI/CD"
  value       = module.ecs.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "cloudwatch_dashboard_url" {
  value = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${module.monitoring.dashboard_name}"
}

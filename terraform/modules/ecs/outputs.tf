output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.app.name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "task_definition_family" {
  value = aws_ecs_task_definition.app.family
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

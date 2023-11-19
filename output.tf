output "ecs_cluster_id" {
  value = aws_ecs_cluster.cluster[*].id
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.cluster[*].arn
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.td.arn
}

output "ecs_task_definition_family" {
  value = aws_ecs_task_definition.td.family
}

output "ecs_task_definition_revision" {
  value = aws_ecs_task_definition.td.revision
}

output "ecs_container_definition_json" {
  value = module.container_definition.json
}

output "ecs_service_id" {
  value = aws_ecs_service.service.id
}

output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_service_desired_count" {
  value = aws_ecs_service.service.desired_count
}

output "cloudwatch_alarm_arn" {
  value = [ for k, v in aws_cloudwatch_metric_alarm.scaling_alarm : v.arn ]
}

output "cloudwatch_alarm_id" {
  value = [ for k, v in aws_cloudwatch_metric_alarm.scaling_alarm : v.id ]
}

output "autoscaling_policy_arn" {
  value = [ for k, v in aws_appautoscaling_policy.scaling_policy : v.arn ]
}

output "autoscaling_policy_policy_type" {
  value = [ for k, v in aws_appautoscaling_policy.scaling_policy : v.policy_type ]
}

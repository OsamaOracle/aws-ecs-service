resource "aws_cloudwatch_metric_alarm" "scaling_alarm" {
  for_each            = var.scaling_alarm
  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.metric_namespace
  period              = each.value.metric_period
  statistic           = each.value.metric_statistic
  threshold           = each.value.alarm_threshold
  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.name
  }
  alarm_actions = [aws_appautoscaling_policy.scaling_policy[each.value.policy_name].arn]
}


resource "aws_appautoscaling_policy" "scaling_policy" {
  for_each           = var.scaling_policy
  name               = each.key
  depends_on         = [aws_appautoscaling_target.scale_target]
  service_namespace  = "ecs"
  resource_id        = format("service/%s/%s", var.cluster_name, var.name)
  scalable_dimension = "ecs:service:DesiredCount"
  policy_type        = each.value.policy_type

  dynamic "step_scaling_policy_configuration" {
    for_each                = each.value.step_scaling_policy_configuration
    content {
      adjustment_type         = "ChangeInCapacity"
      cooldown                = step_scaling_policy_configuration.value.cooldown
      metric_aggregation_type = step_scaling_policy_configuration.value.metric_aggregation_type

      dynamic "step_adjustment" {
        for_each = step_scaling_policy_configuration.value.step_adjustment
        content {
          metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
          metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
          scaling_adjustment          = step_adjustment.value.scaling_adjustment
        }
      }
    }
  }

  dynamic "target_tracking_scaling_policy_configuration" {
    for_each = each.value.target_tracking_scaling_policy_configuration
    content {
      target_value = target_tracking_scaling_policy_configuration.value.target_value
      disable_scale_in = target_tracking_scaling_policy_configuration.value.disable_scale_in
      scale_in_cooldown = target_tracking_scaling_policy_configuration.value.scale_in_cooldown
      scale_out_cooldown = target_tracking_scaling_policy_configuration.value.scale_out_cooldown
      dynamic "predefined_metric_specification" {
        for_each = target_tracking_scaling_policy_configuration.value.predefined_metric_specification
        content {
          predefined_metric_type = predefined_metric_specification.value.type
        }
      }
      dynamic "customized_metric_specification" {
        for_each = target_tracking_scaling_policy_configuration.value.customized_metric_specification
        content {
          metric_name = customized_metric_specification.value.metric_name
          namespace = customized_metric_specification.value.namespace
          statistic = customized_metric_specification.value.statistic
        }
      }
    }
  }
}

resource "aws_appautoscaling_target" "scale_target" {
  service_namespace  = "ecs"
  resource_id        = format("service/%s/%s", var.cluster_name, var.name)
  scalable_dimension = "ecs:service:DesiredCount"
  role_arn           = var.autoscaling_iam_role_arn
  min_capacity       = var.desired_count
  max_capacity       = var.max_capacity

  depends_on         = [aws_ecs_service.service]
}

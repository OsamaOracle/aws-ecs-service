data "aws_caller_identity" "current" {}

resource "aws_ecs_cluster" "cluster" {
  count = var.create_cluster ? 1 : 0
  name = var.cluster_name
  setting {
    name = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.21.0"

  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  port_mappings                = length(var.port_mappings) == 0 ? local.port_mappings : var.port_mappings
  healthcheck                  = var.healthcheck
  container_cpu                = var.container_cpu
  essential                    = var.essential
  entrypoint                   = var.entrypoint
  command                      = var.command
  working_directory            = var.working_directory
  environment                  = var.environment
  secrets                      = var.secrets
  readonly_root_filesystem     = var.readonly_root_filesystem
  mount_points                 = var.mount_points
  dns_servers                  = var.dns_servers
  ulimits                      = var.ulimits
  docker_labels                = var.docker_labels
  repository_credentials       = var.repository_credentials
  volumes_from                 = var.volumes_from
  links                        = var.links
  user                         = var.user
  container_depends_on         = var.container_depends_on
  start_timeout                = var.start_timeout
  stop_timeout                 = var.stop_timeout
  system_controls              = var.system_controls
  firelens_configuration       = var.firelens_configuration
  log_configuration            = var.log_configuration
}

resource "aws_ecs_task_definition" "td" {
  family                = var.name
  container_definitions = "[ ${module.container_definition.json_map} ]"
  task_role_arn         = var.ecs_task_role_arn
  execution_role_arn    = var.ecs_execution_role_arn
  network_mode          = "awsvpc"
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  requires_compatibilities = ["FARGATE"]
  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration
    content {
      container_name = proxy_configuration.value.container_name
      properties     = lookup(proxy_configuration.value, "properties", null)
      type           = lookup(proxy_configuration.value, "type", null)
    }
  }
}

resource "aws_ecs_service" "service" {
  name                               = var.name
  cluster                            = format("arn:aws:ecs:%s:%s:cluster/%s", var.region, data.aws_caller_identity.current.account_id, var.cluster_name)
  task_definition                    = aws_ecs_task_definition.td.arn
  launch_type                        = "FARGATE"
  desired_count                      = var.desired_count
  platform_version                   = var.platform_version
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  propagate_tags                     = var.propagate_tags
  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = lookup(ordered_placement_strategy.value, "field", null)
    }
  }
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      expression = lookup(placement_constraints.value, "expression", null)
      type       = placement_constraints.value.type
    }
  }
  dynamic "service_registries" {
    for_each = var.service_registries
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = lookup(service_registries.value, "port", null)
      container_name = lookup(service_registries.value, "container_name", null)
      container_port = lookup(service_registries.value, "container_port", null)
    }
  }
  network_configuration {
    security_groups  = var.security_group
    subnets          = var.private_subnets
    assign_public_ip = var.assign_public_ip
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

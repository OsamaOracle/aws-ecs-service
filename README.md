# aws-ecs-service

Terraform module to manage AWS ECS Service (Fargate).

This module will create the following:
* ECS cluster
* ECS task definition
* ECS container definition
* Application AutoScaling target
* Application AutoScaling policy
* Cloudwatch metric alarm


## Usage

```hcl
module "proxy_ecs_service" {
  source = "git@github.com:your-repo/aws-ecs-service.git"
  create_cluster = true
  cluster_name = "client-proxy"
  name = "client-proxy"
  container_name = "nginx2"
  container_image = "212312312dkr.ecr.ap-southeast-1.amazonaws.com/client-proxy:9"
  container_memory = "1024"
  container_port = 80
  container_protocol = "tcp"
  container_cpu = 512
  essential = true
  log_configuration = {
    logDriver = "awslogs"
    secretOptions = []
    options = {
      "awslogs-group" = format("/ecs/%s", "nginx2"),
      "awslogs-region" = var.region,
      "awslogs-stream-prefix" = "ecs"
    }
  }
  desired_count = 1
  max_capacity = 10
  platform_version = "LATEST"
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100
  health_check_grace_period_seconds = 120
  security_group = ["sg-023123123123caa"]
  private_subnets = data.terraform_remote_state.network.outputs.vpc_sg_private_subnets
  target_group_arn = var.target_group_arn
  scaling_alarm = {
    scale_up = {
      alarm_name = "client-proxy-cpu-high"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods = 3
      metric_name = "CPUUtilization"
      metric_namespace = "AWS/ECS"
      metric_period = 60
      metric_statistic = "Average"
      alarm_threshold = 50
      policy_name = "client_proxy_scaling_policy"
    },
    scale_down = {
      alarm_name = "client-proxy-cpu-low"
      comparison_operator = "LessThanThreshold"
      evaluation_periods = 15
      metric_name = "CPUUtilization"
      metric_namespace = "AWS/ECS"
      metric_period = 60
      metric_statistic = "Average"
      alarm_threshold = 45
      policy_name = "client_proxy_scaling_policy"
    }
  }
  scaling_policy = {
    client_proxy_scaling_policy = {
      policy_type = "TargetTrackingScaling"
      step_scaling_policy_configuration = []
      target_tracking_scaling_policy_configuration = [
        {
          target_value = 50
          scale_in_cooldown = 300
          scale_out_cooldown = 300
          disable_scale_in = false
          predefined_metric_specification = [
            {
              type = "ECSServiceAverageCPUUtilization"
            }
          ]
          customized_metric_specification = []
        }
      ]
    }
  }
}
```

## Inputs
Name | Description | Type | Default | Required
-----|-------------|------|---------|---------
region | AWS Region | string | eu-west-1 | no
create_cluster | Whether to create ECS cluster or use existing cluster | bool | true | yes
container_port |  Port on which the container is listening. | Integer | null | yes
container_image | The image used to start the container. | string | null | yes
container_name | The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed). | string | null | yes
container_protocol | Protocol used by the container | string | null | yes
enable_container_insights | Whether to enable CloudWatch container insights | bool | false | no
command | The command that is passed to the container. | list | null | no
container_cpu | The number of cpu units to reserve for the container. | integer | 1024 | no
container_depends_on | The dependencies defined for container startup and shutdown. | list | null | no
container_memory | The amount of memory (in MiB) to allow the container to use. | integer | 8192 | no
container_memory_reservation | The amount of memory (in MiB) to reserve for the container. | integer | 2048 | no
dns_servers | Container DNS servers. This is a list of strings specifying the IP addresses of the DNS servers. | list | null | no
docker_labels | The configuration options to send to the `docker_labels` | map | null | no
entrypoint | The entry point that is passed to the container. | list | null | no
environment | The environment variables to pass to the container. This is a list of maps. Each map should contain `name` and `value`. | list | null | no
essential |  Determines whether all other containers in a task are stopped, if this container fails or stops for any reason. | bool | true | no
healthcheck | A map containing command (string), interval (duration in seconds), retries (1-10, number of times to retry before marking container unhealthy, and startPeriod (0-300, optional grace period to wait, in seconds, before failed healthchecks count toward retries). | list | null | no
links | List of container names this container can communicate with without port mappings. | list | null | no
mount_points | Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`. | list | null | no
readonly_root_filesystem | Determines whether a container is given read-only access to its root filesystem. | bool | false | no
repository_credentials | Container repository credentials; required when using a private repo.  This map currently supports a single key; "credentialsParameter", which should be the ARN of a Secrets Manager's secret holding the credentials. | map | null | no
secrets | The secrets to pass to the container. This is a list of maps. | list | null | no
start_timeout | Time duration (in seconds) to wait before giving up on resolving dependencies for a container. | integer | 30 | no
stop_timeout | Timeout in seconds between sending SIGTERM and SIGKILL to container. | integer | 30 | no
ulimits | Container ulimit settings. This is a list of maps, where each map should contain "name", "hardLimit" and "softLimit". | list | null | no
user |  The user to run as inside the container. Can be any of these formats:  user, user:group, uid, uid:gid, user:gid, uid:group. | string | null | no
volumes_from | A list of VolumesFrom maps which contain "sourceContainer" and "readOnly". | list | null | no
working_directory | The working directory to run commands inside the container. | string | null | no
placement_constraints | A set of placement constraints rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. This is a list of maps, where each map should contain "type" and "expression". | list | null | no
proxy_configuration | The proxy configuration details for the App Mesh proxy. This is a list of maps, where each map should contain "container_name", "properties" and "type" | list | [] | no
system_controls | A list of namespaced kernel parameters to set in the container, mapping to the --sysctl option to docker run. This is a list of maps: { namespace = \"\", value = \"\"}" | list | null | no
firelens_configuration | The FireLens configuration for the container. This is used to specify and configure a log router for container logs. | object | null | no
log_configuration | Log configuration options to send to a custom log driver for the container. | object | null | no
task_definition_arn | The full ARN of the task definition that you want to run in your service. | string | null | yes
cluster_name |  Name of the ECS cluster. | string | null | yes
ecs_cluster_arn | ARN of an ECS cluster. | string | null | yes
private_subnets | The private subnets associated with the task or service. | list | null | yes
desired_count | The number of instances of the task definition to place and keep running. | integer | 1 | no
platform_version | The platform version on which to run your service. | string | LATEST | no
deployment_maximum_percent | The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment. | integer | 200 | no
deployment_minimum_healthy_percent | The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment. | integer | 100 | no
enable_ecs_managed_tags | Specifies whether to enable Amazon ECS managed tags for the tasks within the service. | bool | false | no
propagate_tags | Specifies whether to propagate the tags from the task definition or the service to the tasks. The valid values are SERVICE and TASK_DEFINITION | string | SERVICE | no
ordered_placement_strategy | Service level strategy rules that are taken into consideration during task placement. List from top to bottom in order of precedence. The maximum number of ordered_placement_strategy blocks is 5. This is a list of maps where each map should contain "id" and "field". | list | [] | no
health_check_grace_period_seconds | Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 2147483647. Only valid for services configured to use load balancers. | integer | 0 | no
service_registries | The service discovery registries for the service. The maximum number of service_registries blocks is 1. This is a map that should contain the following fields "registry_arn", "port", "container_port" and "container_name". | map | {} | no
security_group | The security groups associated with the task or service. If you do not specify a security group, the default security group for the VPC is used. | list | [] | no
assign_public_ip | Assign a public IP address to the ENI (Fargate launch type only). | bool | false | no
name | ECS service name | string | null | yes
target_group_arn | ARN of the target group | string | null | yes
max_capacity | The max capacity of the scalable target. | number | 5 | no
scaling_policy | A map of application autoscaling policy's configurations | map | {} | no
scaling_alarm | A map of application's cloudwatch metric alarm configurations | map | {} | no
autoscaling_iam_role_arn | The ARN of the IAM role that allows Application AutoScaling to modify your scalable target on your behalf. | string | null | no
ecs_task_role_arn | The ARN of IAM role that allows your Amazon ECS container task to make calls to other AWS services. | string | null | no
ecs_execution_role_arn | The Amazon Resource Name (ARN) of the task execution role that the Amazon ECS container agent and the Docker daemon can assume. | string | null | no

## Outputs
Name | Description
-----|------------
ecs_cluster_id | The Amazon Resource Name (ARN) that identifies the cluster
ecs_cluster_arn | The Amazon Resource Name (ARN) that identifies the cluster
ecs_task_definition_arn | Full ARN of the Task Definition (including both family and revision).
ecs_task_definition_family | The family of the Task Definition.
ecs_task_definition_revision | The revision of the task in a particular family.
ecs_container_definition_json | JSON encoded list of container definitions for use with other terraform resources such as aws_ecs_task_definition
ecs_service_id | The Amazon Resource Name (ARN) that identifies the service
ecs_service_name | The name of the service
ecs_service_desired_count | The number of instances of the task definition
cloudwatch_alarm_arn | The ARN of the cloudwatch metric alarm.
cloudwatch_alarm_id | The ID of the health check
autoscaling_policy_arn | The ARN assigned by AWS to the scaling policy.
autoscaling_policy_policy_type | The scaling policy's type.

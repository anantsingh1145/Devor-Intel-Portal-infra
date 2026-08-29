# https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest/submodules/service
#
# Task definition + ECS service for the Fargate launch type. IAM roles are
# created in modules/iam and passed in (not created here) so the same roles
# can also be referenced by other future services/policies without a cycle.
module "fargate_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.0"

  name        = var.name
  cluster_arn = var.cluster_arn

  cpu    = var.cpu
  memory = var.memory

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  create_task_exec_iam_role = false
  task_exec_iam_role_arn    = var.execution_role_arn

  create_tasks_iam_role = false
  tasks_iam_role_arn    = var.task_role_arn

  container_definitions = {
    (var.name) = {
      image     = var.image
      essential = true
      cpu       = var.cpu
      memory    = var.memory

      readonly_root_filesystem = false

      port_mappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [for k, v in var.environment : { name = k, value = v }]
      secrets     = [for k, arn in var.secrets : { name = k, valueFrom = arn }]

      mount_points = [
        {
          sourceVolume  = "chronicle-data"
          containerPath = var.container_mount_path
          readOnly      = false
        }
      ]

      # No ALB in this architecture, so ECS has no target-group health check
      # to detect a stuck/crashed app — this container-level check is what
      # lets ECS notice and replace an unhealthy task on its own.
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      log_configuration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.name
        }
      }
    }
  }

  volume = {
    "chronicle-data" = {
      efs_volume_configuration = {
        file_system_id     = var.efs_file_system_id
        transit_encryption = "ENABLED"
        authorization_config = {
          access_point_id = var.efs_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  # Tasks run in public subnets (no NAT Gateway, see modules/vpc), so they
  # need a public IP to pull the image from ECR and reach the internet.
  # No ALB in this architecture — that same public IP is also how the app is
  # reached directly (see modules/dns_sync for keeping DNS pointed at it).
  assign_public_ip = true

  desired_count = var.desired_count

  capacity_provider_strategy = {
    FARGATE = {
      capacity_provider = "FARGATE"
      weight            = var.fargate_weight
      base              = var.fargate_base
    }
    FARGATE_SPOT = {
      capacity_provider = "FARGATE_SPOT"
      weight            = var.fargate_spot_weight
    }
  }

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity

  autoscaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"

      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value = var.autoscaling_cpu_target
      }
    }
  }

  tags = var.tags
}

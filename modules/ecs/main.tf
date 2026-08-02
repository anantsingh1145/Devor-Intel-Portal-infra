# https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws/latest
#
# Cluster only. The task definition + service (Fargate-specific resources)
# live in modules/fargate so this module stays reusable if we ever add a
# second service to the same cluster.
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  cluster_name = var.name

  cluster_settings = {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = var.fargate_weight
        base   = var.fargate_base
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = var.fargate_spot_weight
      }
    }
  }

  tags = var.tags
}

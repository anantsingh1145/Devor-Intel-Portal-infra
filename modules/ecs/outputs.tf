output "cluster_id" {
  description = "ECS cluster ID."
  value       = module.ecs_cluster.cluster_id
}

output "cluster_arn" {
  description = "ECS cluster ARN."
  value       = module.ecs_cluster.cluster_arn

  # The cluster resource exists as soon as created, but a service using a
  # capacity_provider_strategy needs the cluster's capacity provider
  # association (FARGATE/FARGATE_SPOT) to exist first too. depends_on the
  # whole module so the fargate service waits for that association, not just
  # the bare cluster.
  depends_on = [module.ecs_cluster]
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs_cluster.cluster_name
}

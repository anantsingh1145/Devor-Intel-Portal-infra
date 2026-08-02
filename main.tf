# Root module: wires every module together using only var.* / module output
# values. This file is identical across dev/preprod/prod — only the values in
# environments/<env>.tfvars change.

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

module "vpc" {
  source = "./modules/vpc"

  name                = "${local.name_prefix}-vpc"
  cidr_block          = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  tags                = local.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  app_port    = var.app_port
  tags        = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_name       = "${var.project_name}-app"
  image_retention_count = var.ecr_image_retention_count
  force_delete          = var.ecr_force_delete
  tags                  = local.common_tags
}

module "acm" {
  source = "./modules/acm"

  domain_name = var.domain_name
  zone_id     = var.route53_zone_id
  tags        = local.common_tags
}

module "lb" {
  source = "./modules/lb"

  name              = "${local.name_prefix}-alb"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id
  app_port          = var.app_port
  health_check_path = var.health_check_path
  certificate_arn   = module.acm.certificate_arn
  tags              = local.common_tags
}

module "efs" {
  source = "./modules/efs"

  name               = "${local.name_prefix}-efs"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.efs_security_group_id]
  posix_uid          = var.efs_posix_uid
  posix_gid          = var.efs_posix_gid
  tags               = local.common_tags
}

module "logs" {
  source = "./modules/logs"

  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_in_days
  tags              = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix             = "${var.project_name}/${var.environment}"
  secrets                 = var.secrets
  recovery_window_in_days = var.environment == "prod" ? 30 : 0
  tags                    = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  name_prefix          = local.name_prefix
  secret_arns          = values(module.secrets.secret_arns)
  efs_file_system_arn  = module.efs.file_system_arn
  efs_access_point_arn = module.efs.access_point_arn
  tags                 = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  name                       = "${local.name_prefix}-cluster"
  container_insights_enabled = var.container_insights_enabled
  fargate_spot_weight        = var.fargate_spot_weight
  tags                       = local.common_tags
}

module "fargate" {
  source = "./modules/fargate"

  name               = "${local.name_prefix}-service"
  cluster_arn        = module.ecs.cluster_arn
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn

  cpu           = var.task_cpu
  memory        = var.task_memory
  desired_count = var.desired_count

  image          = "${module.ecr.repository_url}:${var.image_tag}"
  container_port = var.app_port

  environment = var.app_environment
  secrets     = module.secrets.secret_arns

  log_group_name = module.logs.log_group_name
  aws_region     = var.aws_region

  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.ecs_task_security_group_id]
  target_group_arn   = module.lb.target_group_arn

  efs_file_system_id   = module.efs.file_system_id
  efs_access_point_id  = module.efs.access_point_id
  container_mount_path = var.container_mount_path

  fargate_spot_weight = var.fargate_spot_weight

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_cpu_target   = var.autoscaling_cpu_target

  tags = local.common_tags
}

module "route53" {
  source = "./modules/route53"

  zone_id      = var.route53_zone_id
  domain_name  = var.domain_name
  alb_dns_name = module.lb.alb_dns_name
  alb_zone_id  = module.lb.alb_zone_id
}

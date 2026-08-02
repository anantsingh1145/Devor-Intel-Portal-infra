# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
#
# Three security groups chained by reference (not CIDR) so only traffic that
# should be able to reach a tier can reach it:
#   internet -> alb_sg -> ecs_task_sg -> efs_sg

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name_prefix}-alb-sg"
  description = "Chronicle ALB - allows inbound HTTP/HTTPS from the internet."
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from internet"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS from internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]

  tags = var.tags
}

module "ecs_task_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name_prefix}-ecs-task-sg"
  description = "Chronicle ECS Fargate tasks - allows inbound app traffic only from the ALB."
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = var.app_port
      to_port                  = var.app_port
      protocol                 = "tcp"
      description              = "App traffic from ALB"
      source_security_group_id = module.alb_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = var.tags
}

module "efs_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name_prefix}-efs-sg"
  description = "Chronicle EFS filesystem - allows NFS only from the ECS task security group."
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      description              = "NFS from ECS tasks"
      source_security_group_id = module.ecs_task_sg.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = var.tags
}

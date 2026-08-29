# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
#
# The ALB is the only security group open to the internet; the ECS task only
# accepts traffic from the ALB's security group, never directly from 0.0.0.0/0.
#   internet -> alb_sg -> ecs_task_sg -> efs_sg

module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name_prefix}-alb-sg"
  description = "Chronicle ALB - the only security group open to the internet."
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP from internet, redirected to HTTPS"
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
  description = "Chronicle ECS Fargate task - reachable only from the ALB, never directly from the internet."
  vpc_id      = var.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = var.app_port
      to_port                  = var.app_port
      protocol                 = "tcp"
      description              = "App traffic from the ALB only"
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

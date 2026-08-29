# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/latest
#
# No ALB in this architecture — the ECS task itself is internet-facing (public
# IP, no load balancer in front), so ecs_task_sg takes inbound directly from
# the internet instead of from an ALB security group.
#   internet -> ecs_task_sg -> efs_sg

module "ecs_task_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.name_prefix}-ecs-task-sg"
  description = "Chronicle ECS Fargate task — internet-facing (no ALB), allows inbound app traffic directly."
  vpc_id      = var.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "tcp"
      description = "App traffic from internet"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

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

# https://registry.terraform.io/modules/terraform-aws-modules/alb/aws/latest
#
# HTTP listener always exists. When var.certificate_arn is set, HTTP redirects
# to HTTPS and an HTTPS listener is added; otherwise HTTP forwards directly to
# the target group so environments without a domain (e.g. dev) still work.
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name = var.name

  vpc_id          = var.vpc_id
  subnets         = var.subnet_ids
  security_groups = [var.security_group_id]

  target_groups = {
    chronicle = {
      name_prefix       = "chr-"
      protocol          = "HTTP"
      port              = var.app_port
      target_type       = "ip"
      create_attachment = false

      health_check = {
        enabled             = true
        path                = var.health_check_path
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }

  listeners = merge(
    {
      http = {
        port     = 80
        protocol = "HTTP"

        forward = var.certificate_arn == null ? {
          target_group_key = "chronicle"
        } : null

        redirect = var.certificate_arn != null ? {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        } : null
      }
    },
    var.certificate_arn != null ? {
      https = {
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = var.certificate_arn

        forward = {
          target_group_key = "chronicle"
        }
      }
    } : {}
  )

  tags = var.tags
}

# https://registry.terraform.io/modules/terraform-aws-modules/efs/aws/latest
#
# Persists chronicle.db (SQLite) across Fargate task restarts/redeploys, since
# a Fargate task's local disk is ephemeral. Security groups are managed by
# modules/security_groups, not by this module.
module "efs" {
  source  = "terraform-aws-modules/efs/aws"
  version = "~> 1.6"

  name = var.name

  create_security_group = false

  mount_targets = {
    for idx, subnet_id in var.subnet_ids : idx => {
      subnet_id       = subnet_id
      security_groups = var.security_group_ids
    }
  }

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  access_points = {
    chronicle = {
      posix_user = {
        uid = var.posix_uid
        gid = var.posix_gid
      }
      root_directory = {
        path = var.access_point_path
        creation_info = {
          owner_uid   = var.posix_uid
          owner_gid   = var.posix_gid
          permissions = "755"
        }
      }
    }
  }

  tags = var.tags
}

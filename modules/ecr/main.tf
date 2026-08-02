# https://registry.terraform.io/modules/terraform-aws-modules/ecr/aws/latest
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.2"

  repository_name = var.repository_name
  repository_type = "private"

  repository_image_scan_on_push   = true
  repository_image_tag_mutability = "IMMUTABLE"
  repository_force_delete         = var.force_delete

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.image_retention_count} tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_retention_count
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = var.tags
}

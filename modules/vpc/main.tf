# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr_block

  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = []

  # No NAT Gateway: ECS tasks run in public subnets with public IPs and are
  # reached only through the ALB security group. This is the cost-optimized
  # choice discussed for Chronicle (saves ~$32/month vs. a NAT Gateway) since
  # the app has no need to reach the internet from a private subnet.
  enable_nat_gateway = false
  single_nat_gateway = false

  map_public_ip_on_launch = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

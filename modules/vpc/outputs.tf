output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (used by the ALB, ECS tasks, and EFS mount targets)."
  value       = module.vpc.public_subnets
}

output "azs" {
  description = "Availability zones the VPC's subnets are deployed in."
  value       = module.vpc.azs
}

# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = module.vpc.name
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "secondary_vpc_cidr_block" {
  description = "The secondary CIDR block of the VPC"
  value       = module.vpc.vpc_secondary_cidr_blocks
}

# Subnets
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

# output "secondary_private_subnets" {
#   description = "List of secondary IDs of private subnets"
#   value       = module.vpc.vpc_secondary_cidr_blocks
# }

output "tgw_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.intra_subnets
}

output "eks_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.vpc.database_subnets
}

# Domain name
# output "domain_name" {
#  description = "The Route 53 domain name"
#  value       = var.domain_name
# }

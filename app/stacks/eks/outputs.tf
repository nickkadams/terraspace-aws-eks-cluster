output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

# output "default_node_group_name" {
#   description = "The name of the default EKS Node Group"
#   value       = trimprefix(module.eks.eks_managed_node_groups["mng2"].node_group_id, "${local.name}:")
# }

output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

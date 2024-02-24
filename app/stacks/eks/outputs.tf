output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "default_node_group_name" {
  description = "The name of the default EKS Node Group"
  value       = trimprefix(module.eks.eks_managed_node_groups["default"].node_group_id, "${local.name}:")
}

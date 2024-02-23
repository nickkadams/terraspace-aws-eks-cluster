output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

# output "karpenter_queue_name" {
#   description = "The name of the Karpenter created Amazon SQS queue"
#   value       = module.eks_karpenter.queue_name
# }

# output "karpenter_iam_role_arn" {
#   description = "The Amazon Resource Name (ARN) specifying the Karpenter controller IAM role"
#   value       = module.eks_karpenter.iam_role_arn
# }

# output "karpenter_iam_role_name" {
#   description = "The name of the Karpenter controller IAM role"
#   value       = module.eks_karpenter.iam_role_name
# }

# output "karpenter_node_iam_role_name" {
#   description = "The name of the Karpenter node IAM role"
#   value       = module.eks.eks_managed_node_groups["default"].iam_role_name
# }

# output "cluster_oidc_issuer_url" {
#   description = "The URL on the EKS cluster for the OpenID Connect identity provider"
#   value       = module.eks.cluster_oidc_issuer_url
# }

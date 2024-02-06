module "eks_karpenter" {
  source = "../../modules/eks_karpenter"

  cluster_name = module.eks.cluster_name

  # AWS GovCloud (US) does not currently support Pod Identity
  # https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.htmpodl#pod-id-restrictions
  enable_pod_identity    = false
  enable_irsa            = true
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # Used to attach additional IAM policies to the Karpenter node IAM role
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

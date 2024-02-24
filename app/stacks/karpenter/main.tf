data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "local_file" "karpenter" {
  content = templatefile("${path.module}/templates/karpenter.yaml.tpl",
    {
      karpenter_namespace = var.karpenter_namespace,
      arn_partition       = data.aws_partition.current.partition,
      account_id          = data.aws_caller_identity.current.account_id,
      cluster_name        = var.cluster_name,
      default_nodegroup   = var.default_node_group_name
    }
  )
  filename = "${path.module}/deployments/karpenter.yaml"
}

resource "local_file" "nodepool" {
  content = templatefile("${path.module}/templates/nodepool.yaml.tpl",
    {
      spot_instance_class = var.spot_instance_class,
      cluster_name        = var.cluster_name
    }
  )
  filename = "${path.module}/deployments/nodepool.yaml"
}

output "next_steps" {
  description = "The next steps"
  value       = <<EOT
  kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${var.karpenter_version}/pkg/apis/crds/karpenter.sh_nodepools.yaml
  kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${var.karpenter_version}/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
  kubectl create -f https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${var.karpenter_version}/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
  kubectl apply -f .terraspace-cache/<%= expansion(':REGION') %>/<%= expansion(':APP') %>/<%= expansion(':ENV') %>/stacks/karpenter/deployments/karpenter.yaml
  kubectl apply -f .terraspace-cache/<%= expansion(':REGION') %>/<%= expansion(':APP') %>/<%= expansion(':ENV') %>/stacks/karpenter/deployments/nodepool.yaml
  kubectl logs -f -n ${var.karpenter_namespace} -c controller -l app.kubernetes.io/name=karpenter
  EOT
}
variable "karpenter_version" {
  description = "Karpenter `<major>.<minor>.<patch>` version to use for the Helm chart (i.e.: `0.34.1`)"
  type        = string
  default     = "0.34.1"
}

variable "karpenter_namespace" {
  description = "The Kubernetes namespace for the Karpenter Helm chart deployment"
  type        = string
  default     = "kube-system"
}

variable "spot_instance_class" {
  description = "The desired spot instance class"
  type        = string
  default     = "m5"
}

variable "default_node_group_name" {
  description = "The name of the default EKS Node Group"
  type        = string
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

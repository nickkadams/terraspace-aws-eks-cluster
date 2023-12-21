variable "tag_name" {
  description = "The tag for Name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.28`)"
  type        = string
  default     = 1.28
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "control_plane_subnet_ids" {
  description = "A list of control plane subnets inside the VPC"
  type        = list(string)
  default     = []
}

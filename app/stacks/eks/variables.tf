variable "tag_name" {
  description = "The tag for Name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes `<major>.<minor>` version to use for the EKS cluster (i.e.: `1.28`)"
  type        = string
  default     = 1.29
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

# variable "cluster_service_ipv4_cidr" {
#   description = "A list of the secondary CIDR block of the VPC"
#   type        = list(string)
#   default     = []
# }

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
  default     = []
}

# variable "secondary_private_subnets" {
#   description = "A list of secondary private subnets inside the VPC"
#   type        = list(string)
#   default     = []
# }

variable "control_plane_subnet_ids" {
  description = "A list of control plane subnets inside the VPC"
  type        = list(string)
  default     = []
}

variable "node_group_instance_types" {
  description = "A list of the desired default Node Group instance type(s)"
  type        = list(string)
  default     = ["m5.large"]
}

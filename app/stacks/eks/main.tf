locals {
  name = lower(replace(var.tag_name, ".", "-"))
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get my IP
data "http" "icanhazip" {
  url = "https://ipv4.icanhazip.com"
}

# module "key_pair" {
#   source = "../../modules/key_pair"

#   key_name_prefix    = local.name
#   create_private_key = true
# }

resource "aws_security_group" "remote_access" {
  name_prefix = "${local.name}-remote-access"
  description = "Allow remote SSH access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.icanhazip.response_body)}/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                         = local.name
  cluster_version                      = var.cluster_version
  cluster_enabled_log_types            = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = ["${chomp(data.http.icanhazip.response_body)}/32"]

  authentication_mode = "API_AND_CONFIG_MAP" # "API"

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  # EKS Cluster Add-ons handled in addons.tf via another module:
  # https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
  # cluster_addons

  vpc_id                   = var.vpc_id
  subnet_ids               = var.pod_subnets           # var.private_subnets
  control_plane_subnet_ids = var.control_plane_subnets # var.private_subnets

  iam_role_name            = "Cluster-${local.name}"
  iam_role_use_name_prefix = false

  cluster_encryption_policy_name            = "ClusterEncryption-${local.name}"
  cluster_encryption_policy_use_name_prefix = false

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.node_group_instance_types
  }

  eks_managed_node_groups = {
    bootstrap = {
      name            = "bootstrap-${local.name}"
      use_name_prefix = false

      iam_role_name            = "bootstrap-${local.name}"
      iam_role_use_name_prefix = false

      # subnet_ids = var.private_subnets

      min_size     = 1
      max_size     = 2
      desired_size = 2

      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
    }

    # cis = {
    #   name            = "cis-${local.name}"
    #   use_name_prefix = false

    #   iam_role_name            = "cis-${local.name}"
    #   iam_role_use_name_prefix = false

    #   min_size     = 1
    #   max_size     = 9
    #   desired_size = 2

    #   # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
    #   # so we need to disable it to use the default template provided by the AWS EKS managed node group service
    #   use_custom_launch_template = false

    #   disk_size = 75
    # }
  }

  # Tag security group for Karpenter auto-discovery
  # https://karpenter.sh/docs/getting-started/migrating-from-cas/#add-tags-to-subnets-and-security-groups
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name} --alias ${data.aws_region.current.name}"
  }
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
}

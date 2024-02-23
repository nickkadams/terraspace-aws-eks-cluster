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

  # access_entries = {
  #   # Access entry with a policy associated
  #   karpenter = {
  #     kubernetes_groups = []
  #     principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/KarpenterNodeRole-${local.name}"

  #     policy_associations = {
  #       myapp = {
  #         policy_arn = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "namespace"
  #         }
  #       }
  #     }
  #   }
  # }

  # cluster_addons = {
  #   coredns = {
  #     most_recent = true
  #   }
  #   kube-proxy = {
  #     most_recent = true
  #   }
  #   vpc-cni = {
  #     most_recent = true
  #     before_compute = true
  #     configuration_values = jsonencode({
  #       env = {
  #         ENABLE_POD_ENI                    = "true"
  #         ENABLE_PREFIX_DELEGATION          = "true"
  #         POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
  #       }

  #       enableNetworkPolicy = "true"
  #     })
  #   }
  # }

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets
  # control_plane_subnet_ids = var.control_plane_subnet_ids

  iam_role_name            = "Cluster-${local.name}"
  iam_role_use_name_prefix = false

  cluster_encryption_policy_name            = "ClusterEncryption-${local.name}"
  cluster_encryption_policy_use_name_prefix = false

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.node_group_instance_types

    # metadata_options = {
    #   http_endpoint               = "enabled"
    #   http_tokens                 = "required"
    #   http_put_response_hop_limit = 1
    #   instance_metadata_tags      = "disabled"
    # }
  }

  eks_managed_node_groups = {
    default = {
      name            = "default-${local.name}"
      use_name_prefix = false

      iam_role_name            = "default-${local.name}"
      iam_role_use_name_prefix = false

      min_size     = 1
      max_size     = 5
      desired_size = 2

      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50

      # Remote access cannot be specified with a launch template
      # remote_access = {
      #   ec2_ssh_key               = module.key_pair.key_pair_name
      #   source_security_group_ids = [aws_security_group.remote_access.id]
      # }

      # iam_role_name            = "ClusterAutoscalerNodeRole-${local.name}"
      # iam_role_use_name_prefix = false

      # Used to attach the Cluster-Autoscaler node IAM role policy
      # iam_role_additional_policies = {
      #   additional = aws_iam_policy.cluster_autoscaler.arn
      # }
    }
  }

  # Tag security group for Karpenter auto-discovery
  # https://karpenter.sh/docs/getting-started/migrating-from-cas/#add-tags-to-subnets-and-security-groups
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.name
  }
}

resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${data.aws_region.current.name} update-kubeconfig --name ${module.eks.cluster_name} --alias ${data.aws_region.current.name}"
  }
  # triggers = {
  #   always_run = "${timestamp()}"
  # }
}

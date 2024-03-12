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

  authentication_mode = "API" # "API_AND_CONFIG_MAP"

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  # EKS Cluster Add-ons handled in addons.tf via another module:
  # https://github.com/aws-ia/terraform-aws-eks-blueprints-addons
  # cluster_addons

  vpc_id                   = var.vpc_id
  control_plane_subnet_ids = var.control_plane_subnets # var.private_subnets
  subnet_ids               = var.pod_subnets           # var.private_subnets

  iam_role_name            = "cluster-${local.name}"
  iam_role_use_name_prefix = false
  iam_role_description     = "Cluster IAM role"

  cluster_encryption_policy_name            = "cluster-encryption-${local.name}"
  cluster_encryption_policy_use_name_prefix = false

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.node_group_instance_types

    # Add IAM policy to managed node groups for Karpenter
    # https://karpenter.sh/docs/getting-started/migrating-from-cas/#create-iam-roles
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    mng1 = {
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

      disk_size = 75
    }

    # mng2 = {
    #   name            = "cis-${local.name}"
    #   use_name_prefix = false

    #   iam_role_name            = "cis-${local.name}"
    #   iam_role_use_name_prefix = false

    #   min_size     = 1
    #   max_size     = 9
    #   desired_size = 2

    #   launch_template_name            = "cis-${local.name}"
    #   launch_template_use_name_prefix = false

    #   ami_type                   = "AL2_x86_64"
    #   ami_id                     = "ami-0f97c28235ecea933" # data.aws_ami.eks_cis.image_id
    #   enable_bootstrap_user_data = true

    #   instance_types = var.node_group_instance_types

    #   block_device_mappings = {
    #     xvda = {
    #       device_name = "/dev/xvda"
    #       ebs = {
    #         volume_size = 75
    #         volume_type = "gp3"
    #         iops        = 3000
    #         throughput  = 150
    #         # encrypted             = true
    #         # kms_key_id            = module.ebs_kms_key.key_arn
    #         delete_on_termination = true
    #       }
    #     }
    #   }

    #   # https://aws.github.io/aws-eks-best-practices/security/docs/iam/#identities-and-credentials-for-eks-pods-recommendations
    #   metadata_options = {
    #     http_endpoint               = "enabled"
    #     http_tokens                 = "required"
    #     http_put_response_hop_limit = 1
    #     instance_metadata_tags      = "enabled"
    #   }

    #   # iam_role_additional_policies = {
    #   #  AmazonEC2ContainerRegistryReadOnly = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    #   # }
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

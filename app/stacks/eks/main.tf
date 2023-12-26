locals {
  name = lower(replace(var.tag_name, ".", "-"))
}

data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# Get my IP
data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"]
    #values = ["bottlerocket-aws-k8s-${var.cluster_version}-aarch64-*"]
  }
}

module "key_pair" {
  source = "../../modules/key-pair"

  key_name_prefix    = local.name
  create_private_key = true
}

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

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.control_plane_subnet_ids

  manage_aws_auth_configmap = true

  # aws_auth_users = [
  #   {
  #     userarn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/myuser2"
  #     username = "myuser2"
  #     groups   = ["system:masters"]
  #   },
  #   {
  #     userarn  = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:user/myuser3"
  #     username = "myuser3"
  #     groups   = ["system:masters"]
  #   }
  # ]

  cluster_tags = {
    Environment = "<%= expansion(':ENV') %>"
    Owner       = "<%= expansion(':APP') %>"
    Terraform   = "true"
    VCS         = "true"
    Workspace   = terraform.workspace
  }  

  eks_managed_node_group_defaults = {
    desired_size  = 1
    min_size      = 0
    max_size      = 15
    capacity_type = "ON_DEMAND"
    platform      = "bottlerocket"
    ami_id        = data.aws_ami.eks_default_bottlerocket.id
    # ami_type       = "AL2_x86_64"
    instance_types = ["t3.small", "t3.medium", "t3.large"]
    iam_role_additional_policies = {
      additional = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    # We are using the IRSA created below for permissions
    # However, we have to deploy with the policy attached FIRST (when creating a fresh cluster)
    # and then turn this off after the cluster/node group is created. Without this initial policy,
    # the VPC CNI fails to assign IPs and nodes cannot join the cluster
    # See https://github.com/aws/containers-roadmap/issues/1666 for more context
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    # Default node group
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false

      disk_size = 50

      # This will get added to what AWS provides
      bootstrap_extra_args = <<-EOT
        # extra args added
        [settings.kernel]
        lockdown = "integrity"
      EOT

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = module.key_pair.key_pair_name
        source_security_group_ids = [aws_security_group.remote_access.id]
      }
    }
  }
}


locals {
  template_path = {
    al2023       = "${path.module}/../../templates/al2023_user_data.tpl"
    bottlerocket = "${path.module}/../../templates/bottlerocket_user_data.tpl"
    linux        = "${path.module}/../../templates/linux_user_data.tpl"
    windows      = "${path.module}/../../templates/windows_user_data.tpl"
  }

  user_data = base64encode(templatefile(
    coalesce(var.user_data_template_path, local.template_path[var.platform]),
    {
      # https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-custom-ami
      enable_bootstrap_user_data = var.enable_bootstrap_user_data

      # Required to bootstrap node
      cluster_name        = var.cluster_name
      cluster_endpoint    = var.cluster_endpoint
      cluster_auth_base64 = var.cluster_auth_base64

      # Optional
      cluster_service_ipv4_cidr = var.cluster_service_ipv4_cidr != null ? var.cluster_service_ipv4_cidr : ""
      bootstrap_extra_args      = var.bootstrap_extra_args
      pre_bootstrap_user_data   = var.pre_bootstrap_user_data
      post_bootstrap_user_data  = var.post_bootstrap_user_data
    }
  ))

  platform = {
    al2023 = {
      user_data = var.create ? try(data.cloudinit_config.al2023_eks_managed_node_group[0].rendered, local.user_data) : ""
    }
    bottlerocket = {
      user_data = var.create && var.platform == "bottlerocket" && (var.enable_bootstrap_user_data || var.user_data_template_path != "" || var.bootstrap_extra_args != "") ? local.user_data : ""
    }
    linux = {
      user_data = var.create ? try(data.cloudinit_config.linux_eks_managed_node_group[0].rendered, local.user_data) : ""
    }
    windows = {
      user_data = var.create && var.platform == "windows" && (var.enable_bootstrap_user_data || var.user_data_template_path != "" || var.pre_bootstrap_user_data != "") ? local.user_data : ""
    }
  }
}

# https://github.com/aws/containers-roadmap/issues/596#issuecomment-675097667
# Managed nodegroup data must in MIME multi-part archive format,
# as by default, EKS will merge the bootstrapping command required for nodes to join the
# cluster with your user data. If you use a custom AMI in your launch template,
# this merging will NOT happen and you are responsible for nodes joining the cluster.
# See docs for more details -> https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data

data "cloudinit_config" "linux_eks_managed_node_group" {
  count = var.create && var.platform == "linux" && var.is_eks_managed_node_group && !var.enable_bootstrap_user_data && var.pre_bootstrap_user_data != "" && var.user_data_template_path == "" ? 1 : 0

  base64_encode = true
  gzip          = false
  boundary      = "//"

  # Prepend to existing user data supplied by AWS EKS
  part {
    content      = var.pre_bootstrap_user_data
    content_type = "text/x-shellscript"
  }
}

# Scenarios:
#
# 1. Do nothing - provide nothing
# 2. Prepend stuff on EKS MNG (before EKS MNG adds its bit at the end)
# 3. Own all of the stuff on self-MNG or EKS MNG w/ custom AMI

locals {
  nodeadm_cloudinit = var.enable_bootstrap_user_data ? concat(
    var.cloudinit_pre_nodeadm,
    [{
      content_type = "application/node.eks.aws"
      content      = base64decode(local.user_data)
    }],
    var.cloudinit_post_nodeadm
  ) : var.cloudinit_pre_nodeadm
}

data "cloudinit_config" "al2023_eks_managed_node_group" {
  count = var.create && var.platform == "al2023" && length(local.nodeadm_cloudinit) > 0 ? 1 : 0

  base64_encode = true
  gzip          = false
  boundary      = "MIMEBOUNDARY"

  dynamic "part" {
    # Using the index is fine in this context since any change in user data will be a replacement
    for_each = { for i, v in local.nodeadm_cloudinit : i => v }

    content {
      content      = part.value.content
      content_type = try(part.value.content_type, null)
      filename     = try(part.value.filename, null)
      merge_type   = try(part.value.merge_type, null)
    }
  }
}

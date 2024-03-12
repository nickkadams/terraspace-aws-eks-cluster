locals {
  name = lower(replace(var.tag_name, ".", "-"))
}

# https://wolfman.dev/posts/exclude-use1-az3/
# https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#network-requirements-subnets
data "aws_availability_zones" "available" {
  state = "available"
  #exclude_zone_ids = ["use1-az3", "usw1-az2", "cac1-az3"]
}

data "aws_caller_identity" "current" {}

#tfsec:ignore:aws-vpc-no-default-vpc
module "vpc" {
  source = "../../modules/vpc"

  name = local.name

  cidr = var.aws_network

  # Use 100.64.0.0/10 space for VPC CNI
  # You can add up to 5 total CIDR blocks
  secondary_cidr_blocks = [var.secondary_aws_network]

  # 3-AZs
  azs                 = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]
  public_subnets      = [cidrsubnet(var.aws_network, 4, 12), cidrsubnet(var.aws_network, 4, 13), cidrsubnet(var.aws_network, 4, 14)]
  private_subnets     = [cidrsubnet(var.aws_network, 2, 0), cidrsubnet(var.aws_network, 2, 1), cidrsubnet(var.aws_network, 2, 2)]
  intra_subnets       = [cidrsubnet(var.aws_network, 12, 3843), cidrsubnet(var.aws_network, 12, 3844), cidrsubnet(var.aws_network, 12, 3845)]
  elasticache_subnets = [cidrsubnet(var.aws_network, 12, 3840), cidrsubnet(var.aws_network, 12, 3841), cidrsubnet(var.aws_network, 12, 3842)]
  database_subnets    = [cidrsubnet(var.secondary_aws_network, 2, 0), cidrsubnet(var.secondary_aws_network, 2, 1), cidrsubnet(var.secondary_aws_network, 2, 2)]
  # redshift_subnets    = [cidrsubnet(var.secondary_aws_network, 12, 3843), cidrsubnet(var.secondary_aws_network, 12, 3844), cidrsubnet(var.secondary_aws_network, 12, 3845)]

  # Intra
  intra_subnet_suffix = "tgw"

  # Elasticache
  elasticache_subnet_suffix             = "eks"
  create_elasticache_subnet_group       = false
  create_elasticache_subnet_route_table = true

  # Database
  database_subnet_suffix             = "pod"
  create_database_subnet_group       = false
  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = true

  # Redshift
  # redshift_subnet_suffix             = "tgw-cg"
  # create_redshift_subnet_group       = false
  # create_redshift_subnet_route_table = true

  # ACLs
  public_dedicated_network_acl  = true
  private_dedicated_network_acl = false
  intra_dedicated_network_acl   = true

  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html#vpc-cidr
  map_public_ip_on_launch = true

  # NAT/VPN
  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = false

  # DNS options
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_dhcp_options  = true
  #dhcp_options_domain_name         = "${data.aws_region.current.name}.${var.domain_name}"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  # Default route table with 0 subnet associations
  manage_default_route_table = true

  default_route_table_tags = {
    Name = "${local.name}-default"
  }

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  default_security_group_tags = {
    Name = "${local.name}-default"
  }

  database_subnet_tags = {
    Tier                              = "pod"
    "kubernetes.io/role/internal-elb" = 1
    # Tag subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = local.name
  }

  private_subnet_tags = {
    Tier = "private"
    # "kubernetes.io/role/internal-elb" = 1
    # # Tag subnets for Karpenter auto-discovery
    # "karpenter.sh/discovery" = local.name
  }

  public_subnet_tags = {
    Tier                     = "public"
    "kubernetes.io/role/elb" = 1
  }
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"

  filter {
    name   = "service-type"
    values = ["Gateway"]
  }
}

data "aws_iam_policy_document" "dynamodb_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"

      values = [data.aws_vpc_endpoint_service.dynamodb.id]
    }
  }
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [data.aws_security_group.default.id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"

      tags = {
        Name = local.name
      }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([module.vpc.public_route_table_ids, module.vpc.private_route_table_ids, module.vpc.database_route_table_ids])
      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json

      tags = {
        Name = local.name
      }
    }
  }
}

# Secondary CIDR range + private NAT gateway
# https://itnext.io/eks-and-the-quest-for-ip-addresses-secondary-cidr-ranges-and-private-nat-gateways-1f5c69473a40
resource "aws_nat_gateway" "private_cg" {
  count = 3

  connectivity_type = "private"

  subnet_id = element(
    module.vpc.database_subnets,
    count.index,
  )

  tags = merge(
    {
      "Name" = format(
        "${local.name}-private-%s",
        element(module.vpc.azs, false ? 0 : count.index),
      )
    }
  )
}

resource "aws_route" "private_cg_nat_gateway" {
  count = 3

  route_table_id         = element(module.vpc.database_route_table_ids, count.index)
  destination_cidr_block = "172.16.0.0/12"
  nat_gateway_id         = element(aws_nat_gateway.private_cg[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

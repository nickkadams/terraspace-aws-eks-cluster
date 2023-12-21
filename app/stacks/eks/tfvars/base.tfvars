tag_name = "<%= Terraspace.app %>-<%= Terraspace.env %>"

vpc_id = <%= output('vpc.vpc_id') %>

private_subnets = <%= output('vpc.private_subnets') %>

control_plane_subnet_ids = <%= output('vpc.eks_subnets') %>

tag_name = "<%= Terraspace.app %>-<%= Terraspace.env %>"

vpc_id = <%= output('vpc.vpc_id') %>

private_subnets = <%= output('vpc.private_subnets') %>

pod_subnets = <%= output('vpc.pod_subnets') %>

control_plane_subnets = <%= output('vpc.eks_subnets') %>

azs = <%= output('vpc.azs') %>

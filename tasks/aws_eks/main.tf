resource "aws_vpc" "test-vpc" {
  cidr_block = var.cidr
}

resource "aws_subnet" "pub_sub1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "pub_sub2" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"
  tags = {
    "kubernetes.io/role/elb" = 1 
  }
}


resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_route_table" "routetable1" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table_association" "association1" {
  subnet_id = aws_subnet.pub_sub1.id
  route_table_id = aws_route_table.routetable1.id
}

resource "aws_route_table_association" "association2" {
  subnet_id = aws_subnet.pub_sub2.id
  route_table_id = aws_route_table.routetable1.id
}

resource "aws_security_group" "mysg" {
  name_prefix = "eks-cluster-sg-tf-"
  vpc_id = aws_vpc.test-vpc.id
}

resource "aws_security_group_rule" "ingress_rule_1" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_2" {
  type              = "egress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}

resource "aws_security_group_rule" "egress_rule_3" {
  type              = "egress"
  from_port         = 53
  to_port           = 53
  protocol          = "tcp"
  source_security_group_id = aws_security_group.mysg.id
  security_group_id = aws_security_group.mysg.id
}


resource "aws_eip" "eip1" {
}

resource "aws_eip" "eip2" {
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.eip1.allocation_id
  subnet_id = aws_subnet.pub_sub1.id
  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.eip2.allocation_id
  subnet_id = aws_subnet.pub_sub2.id
  depends_on = [ aws_internet_gateway.my_igw ]
}

resource "aws_subnet" "pvt_sub1" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "pvt_sub2" {
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
    tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_route_table" "pvt_routetable1" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
}

resource "aws_route_table" "pvt_routetable2" {
  vpc_id = aws_vpc.test-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat2.id
  }
}

resource "aws_route_table_association" "pvt_association1" {
  subnet_id = aws_subnet.pvt_sub1.id
  route_table_id = aws_route_table.pvt_routetable1.id
}

resource "aws_route_table_association" "pvt_association2" {
  subnet_id = aws_subnet.pvt_sub2.id
  route_table_id = aws_route_table.pvt_routetable2.id
}

# resource "aws_eks_cluster" "clusterx" {
#   name = var.cluster_name
#   version = 1.29
#   access_config {
#     authentication_mode = "API_AND_CONFIG_MAP"
#     bootstrap_cluster_creator_admin_permissions = true
#   }
  
#   role_arn = "arn:aws:iam::377830127496:role/myAmazonEKSClusterRole"
#   vpc_config {
#     subnet_ids = [ aws_subnet.pub_sub1.id, aws_subnet.pub_sub2.id ]
#     endpoint_private_access = true
#     endpoint_public_access = true
#   }
#   depends_on = [aws_cloudwatch_log_group.cp_log_group]
#   enabled_cluster_log_types = ["api", "audit","authenticator","controllerManager","scheduler"]

# }

# resource "aws_eks_addon" "vpc_cni" {
#   cluster_name = aws_eks_cluster.clusterx.name
#   addon_name   = "vpc-cni"
#   addon_version = "v1.18.1-eksbuild.3"
# }
# resource "aws_eks_addon" "coredns" {
#   cluster_name = aws_eks_cluster.clusterx.name
#   addon_name   = "coredns"
#   addon_version = "v1.11.1-eksbuild.4"
# }

# resource "aws_eks_addon" "kube-proxy" {
#   cluster_name = aws_eks_cluster.clusterx.name
#   addon_name   = "kube-proxy"
#   addon_version = "v1.29.3-eksbuild.2"
# }
# resource "aws_cloudwatch_log_group" "cp_log_group" {
#   name              = "/aws/eks/${var.cluster_name}/cluster/${var.date}"
#   retention_in_days = 7
# }

# resource "aws_eks_node_group" "node_group" {
#   cluster_name = aws_eks_cluster.clusterx.name
#   node_group_name = "node_group"
#   node_role_arn = "arn:aws:iam::377830127496:role/eksCustomNodeRole"
#   subnet_ids = [aws_subnet.pvt_sub1.id, aws_subnet.pvt_sub2.id]
#   scaling_config {
#     desired_size = 2
#     max_size = 2
#     min_size = 2
#   }
#   update_config {
#     max_unavailable = 1
#   }
# }
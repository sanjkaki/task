# output "endpoint" {
#   value = aws_eks_cluster.clusterx.endpoint
# }

# output "kubeconfig-certificate-authority-data" {
#   value = aws_eks_cluster.clusterx.certificate_authority[0].data
# }
output "pub_subnet_id1" {
  description = "Public subnet ID 1"
  value = aws_subnet.pub_sub1.id
}
output "pub_subnet_id2" {
    description = "Public subnet ID 2"
  value = aws_subnet.pub_sub2.id
}

output "pvt_subnet_id1" {
  description = "Private subnet ID 1"
  value = aws_subnet.pvt_sub1.id
}
output "pvt_subnet_id2" {
    description = "Private subnet ID 2"
  value = aws_subnet.pvt_sub2.id
}


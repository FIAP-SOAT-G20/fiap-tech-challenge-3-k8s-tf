output "cluster_name" {
  value = aws_eks_cluster.eks-cluster.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks-cluster.endpoint
}

output "vpc_arn" {
  value = data.aws_vpc.vpc.arn
}

output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = data.aws_vpc.vpc.cidr_block
}

output "security_group_id" {
  value = aws_security_group.sg.id
}

output "subnet_ids" {
  value = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.region}e"]
}

output "lab_role_arn" {
  value = var.lab_role
}

output "principal_arn" {
  value = var.principal_arn
}

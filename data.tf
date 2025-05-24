data "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  # enable_dns_support = true
  # tags = var.tags
}

data "aws_subnets" "subnets"{
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.vpc.id]
    }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
  # tags = var.tags
}

data "aws_iam_role" "fiap_lab_role" {
  name = "LabRole"
}

# data "aws_iam_role" "voclabs_role" {
#   name = "voclabs"
# }

data "aws_eks_cluster" "eks_cluster" {
  name = var.project_name
}

data "aws_eks_cluster_auth" "eks_cluster_auth" {
  name = var.project_name
}


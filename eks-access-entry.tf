resource "aws_eks_access_entry" "eks-access-entry" {
  cluster_name      = aws_eks_cluster.eks-cluster.name
  principal_arn     = var.principal_arn # data.aws_iam_role.voclabs_role.assume_role_policy.arn
  kubernetes_groups = ["fiap"]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks-access-policy" {
  cluster_name  = aws_eks_cluster.eks-cluster.name
  policy_arn    = var.policy_arn
  principal_arn = data.aws_iam_role.voclabs_role.assume_role_policy.arn

  access_scope {
    type = "cluster"
  }
}

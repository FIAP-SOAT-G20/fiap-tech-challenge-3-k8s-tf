resource "aws_eks_cluster" "eks-cluster" {
  name     = var.project_name
  role_arn = data.aws_iam_role.fiap_lab_role.arn

  vpc_config {
    subnet_ids         = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.region}e"]
    security_group_ids = [aws_security_group.sg.id]
  }

  access_config {
    authentication_mode = var.access_config
  }
}

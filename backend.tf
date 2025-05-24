terraform {
  backend "s3" {
    bucket = "ff-tech-challenge-eks-cluster-backend-tf"
    key = "fiap/k8s/terraform.tfstate"
    region = "us-east-1"
  }
}

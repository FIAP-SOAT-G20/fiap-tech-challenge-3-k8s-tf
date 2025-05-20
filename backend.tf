terraform {
  backend "s3" {
    bucket = "ff-tech-challenge-eks-cluster-backend-tf"
    key = "fiap/terraform.tfstate"
    region = "us-east-1"
  }
}

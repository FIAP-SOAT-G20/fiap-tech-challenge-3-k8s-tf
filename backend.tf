terraform {
  backend "s3" {
    bucket = "fast-food-terraform-state-g22-tc3"
    key = "fiap/k8s/terraform.tfstate"
    region = "us-east-1"
  }
}

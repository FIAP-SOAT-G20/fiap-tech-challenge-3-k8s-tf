# FIAP-TechChallenge-Fase3-Terraform


https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks

aws eks --region $(terraform output -raw region) update-kubeconfig \
    --name $(terraform output -raw cluster_name)

kubectl cluster-info

kubectl get nodes

NAMESPACE=tech-challenge-ns
AWS_EKS_CLUSTER_NAME=ff-tech-challenge-eks-cluster

# Looks at comments using ## on targets and uses them to produce a help output.
.PHONY: help
help: ALIGN=22
help: ## Print this message
	@echo "Usage: make <command>"
	@awk -F '::? .*## ' -- "/^[^':]+::? .*## /"' { printf "  make '$$(tput bold)'%-$(ALIGN)s'$$(tput sgr0)' - %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: tf-init
tf-init: ## Initialize Terraform
	@echo  "🟢 Initializing Terraform..."
	terraform init

.PHONY: tf-plan
tf-plan: ## Show Terraform plan
	@echo  "🟢 Showing Terraform plan..."
	terraform plan

.PHONY: tf-apply
tf-apply: ## Apply Terraform
	@echo  "🟢 Applying Terraform..."
	terraform apply -auto-approve


.PHONY: aws-eks-auth
aws-eks-auth: ## Update kubeconfig for the newly created EKS cluster
	@echo  "🟢 Updating kubeconfig for the EKS cluster..."
	aws eks update-kubeconfig --name $(AWS_EKS_CLUSTER_NAME)
# aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)

.PHONY: k8s-apply
k8s-apply: ## Apply Kubernetes manifests
	@echo  "🟢 Applying Kubernetes manifests..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/mockserver/
	kubectl apply -f k8s/config/
	kubectl apply -f k8s/app/

.PHONY: k8s-delete
k8s-delete: ## Delete Kubernetes resources
	@echo  "🔴 Deleting Kubernetes resources..."
	kubectl apply -f k8s/mockserver/
	kubectl delete -f k8s/app/
	kubectl delete -f k8s/config/
	kubectl delete -f k8s/namespace.yaml

.PHONY: k8s-logs
k8s-logs: ## Show application logs
	@echo  "🟢 Showing application logs..."
	kubectl logs -f -l app=product-api -n $(NAMESPACE)

.PHONY: k8s-status
k8s-status: ## Show Kubernetes resources status
	@echo  "🟢 Showing Kubernetes resources status..."
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE)
	@echo "\n=== Services ==="
	kubectl get svc -n $(NAMESPACE)
	@echo "\n=== Deployments ==="
	kubectl get deploy -n $(NAMESPACE)
	@echo "\n=== HPA ==="
	kubectl get hpa -n $(NAMESPACE)
	@echo "\n=== Ingress ==="
	kubectl get ingress -n $(NAMESPACE)
	@echo "\n=== ConfigMaps ==="
	kubectl get configmaps -n $(NAMESPACE)
	@echo "\n=== Secrets ==="
	kubectl get secrets -n $(NAMESPACE)

k8s-set-namespace: ## Set Kubernetes namespace
	@echo  "🟢 Setting Kubernetes namespace..."
	kubectl config set-context --current --namespace=$(NAMESPACE)


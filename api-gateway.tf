# AWS API Gateway for EKS
resource "aws_api_gateway_rest_api" "eks_api" {
  name        = "eks-api-gateway"
  description = "API Gateway for EKS cluster"
}

# API Gateway Resource for proxy path
resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.eks_api.id
  parent_id   = aws_api_gateway_rest_api.eks_api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method for the proxy resource
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.eks_api.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# API Gateway Method for the root resource
resource "aws_api_gateway_method" "root_method" {
  rest_api_id   = aws_api_gateway_rest_api.eks_api.id
  resource_id   = aws_api_gateway_rest_api.eks_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# Data source para buscar o Classic Load Balancer criado pelo Kubernetes
data "aws_elb" "k8s_loadbalancer" {
  name = "a16a88e97612b4542bb399d1ba8dfb9c"
}

# API Gateway Integration usando o Load Balancer do Kubernetes
resource "aws_api_gateway_integration" "eks_integration" {
  rest_api_id = aws_api_gateway_rest_api.eks_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = aws_api_gateway_method.proxy_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri = "http://${data.aws_elb.k8s_loadbalancer.dns_name}/{proxy}"
  passthrough_behavior    = "WHEN_NO_MATCH"

  request_parameters = {
    "integration.request.path.proxy"    = "method.request.path.proxy"
    "integration.request.header.Accept" = "'application/json'"
  }
}

# API Gateway Integration for the root resource
resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id = aws_api_gateway_rest_api.eks_api.id
  resource_id = aws_api_gateway_rest_api.eks_api.root_resource_id
  http_method = aws_api_gateway_method.root_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri = "http://${data.aws_elb.k8s_loadbalancer.dns_name}/"
  passthrough_behavior    = "WHEN_NO_MATCH"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "eks_deployment" {
  depends_on = [
    aws_api_gateway_integration.eks_integration,
    aws_api_gateway_integration.root_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.eks_api.id

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "eks_stage" {
  deployment_id = aws_api_gateway_deployment.eks_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.eks_api.id
  stage_name    = "prod"
}

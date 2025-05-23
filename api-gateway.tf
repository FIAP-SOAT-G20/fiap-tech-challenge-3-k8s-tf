# AWS API Gateway for EKS
resource "aws_api_gateway_rest_api" "eks_api" {
  name        = "eks-api-gateway"
  description = "API Gateway for EKS cluster"
}

# VPC Link for connecting API Gateway to the EKS cluster
resource "aws_api_gateway_vpc_link" "eks_vpc_link" {
  name = "eks-vpc-link"
  target_arns = [aws_lb.eks_nlb.arn]
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
    "method.request.path.proxy"           = true
    "method.request.header.Authorization" = true
  }
}

# API Gateway Integration with the VPC Link
resource "aws_api_gateway_integration" "eks_integration" {
  rest_api_id = aws_api_gateway_rest_api.eks_api.id
  resource_id = aws_api_gateway_resource.proxy_resource.id
  http_method = "ANY"

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.eks_nlb.dns_name}/{proxy}"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks_vpc_link.id

  request_parameters = {
    "integration.request.path.proxy"           = "method.request.path.proxy"
    "integration.request.header.Accept"        = "'application/json'"
    "integration.request.header.Authorization" = "method.request.header.Authorization"
  }
}

# API Gateway Method for the root resource
resource "aws_api_gateway_method" "root_method" {
  rest_api_id   = aws_api_gateway_rest_api.eks_api.id
  resource_id   = aws_api_gateway_rest_api.eks_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Integration for the root resource
resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id = aws_api_gateway_rest_api.eks_api.id
  resource_id = aws_api_gateway_rest_api.eks_api.root_resource_id
  http_method = aws_api_gateway_method.root_method.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${aws_lb.eks_nlb.dns_name}/"
  passthrough_behavior    = "WHEN_NO_MATCH"
  content_handling        = "CONVERT_TO_TEXT"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks_vpc_link.id
}


# Network Load Balancer for the EKS cluster
resource "aws_lb" "eks_nlb" {
  name               = "eks-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [for subnet in data.aws_subnet.subnet : subnet.id if subnet.availability_zone != "${var.regionDefault}e"]

  enable_deletion_protection = false
}

# Target group for the NLB
resource "aws_lb_target_group" "eks_tg" {
  name        = "eks-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    interval            = 30
    port                = 8080
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


# NLB Listener
resource "aws_lb_listener" "eks_listener" {
  load_balancer_arn = aws_lb.eks_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_tg.arn
  }
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

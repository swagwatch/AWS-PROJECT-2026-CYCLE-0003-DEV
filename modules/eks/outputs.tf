# Cluster Outputs
output "cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.main.status
}

# Security Group Outputs
output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# IAM Outputs
output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_eks_cluster.main.role_arn
}

output "node_iam_role_arn" {
  description = "IAM role ARN of the EKS node groups"
  value       = var.create_node_role ? aws_iam_role.node[0].arn : null
}

output "node_iam_role_name" {
  description = "IAM role name of the EKS node groups"
  value       = var.create_node_role ? aws_iam_role.node[0].name : null
}

# OIDC Provider Outputs
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = var.enable_irsa ? replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "") : null
}

# Certificate Authority Output
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# Node Group Outputs
output "node_groups" {
  description = "Outputs from EKS node groups"
  value = {
    for k, v in aws_eks_node_group.main : k => {
      id              = v.id
      arn             = v.arn
      status          = v.status
      capacity_type   = v.capacity_type
      node_group_name = v.node_group_name
      resources       = v.resources
    }
  }
}

# VPC Configuration Output
output "cluster_vpc_config" {
  description = "VPC configuration of the cluster"
  value = {
    vpc_id                  = aws_eks_cluster.main.vpc_config[0].vpc_id
    subnet_ids              = aws_eks_cluster.main.vpc_config[0].subnet_ids
    security_group_ids      = aws_eks_cluster.main.vpc_config[0].security_group_ids
    endpoint_private_access = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    endpoint_public_access  = aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    public_access_cidrs     = aws_eks_cluster.main.vpc_config[0].public_access_cidrs
  }
}

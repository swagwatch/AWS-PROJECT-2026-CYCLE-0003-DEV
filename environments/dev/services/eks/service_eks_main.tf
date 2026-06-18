# EKS Module Implementation for Dev Environment
module "eks" {
  source = "../../modules/eks"

  # Cluster Configuration
  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version

  # VPC Configuration
  subnet_ids                  = var.subnet_ids
  cluster_security_group_ids  = var.cluster_security_group_ids

  # Endpoint Access Configuration
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  # Encryption Configuration
  enable_encryption = var.enable_encryption
  kms_key_arn       = var.kms_key_arn

  # Logging Configuration
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # IAM Configuration
  create_cluster_role = var.create_cluster_role
  cluster_role_arn    = var.cluster_role_arn
  create_node_role    = var.create_node_role

  # Node Groups Configuration
  node_groups = var.node_groups

  # IRSA Configuration
  enable_irsa = var.enable_irsa

  # Tagging
  common_tags = local.common_tags
  tags        = var.tags
}

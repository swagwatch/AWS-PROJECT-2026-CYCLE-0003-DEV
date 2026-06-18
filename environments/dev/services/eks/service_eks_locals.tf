# Local values for EKS service
locals {
  # Cluster name with environment prefix
  cluster_name = "dev-eks-cluster"

  # Common tags for all EKS resources
  common_tags = {
    Environment = "dev"
    Owner       = "platform-team"
    Project     = "eks-infrastructure"
    ManagedBy   = "terraform"
    Service     = "eks"
  }
}

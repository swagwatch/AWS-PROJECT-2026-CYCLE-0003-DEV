# EKS Cluster Configuration for Dev Environment

# Cluster Settings
kubernetes_version = "1.28"

# VPC Configuration
subnet_ids = ["subnet-12345678", "subnet-87654321"]

# Endpoint Access Configuration
endpoint_private_access = true
endpoint_public_access  = false
public_access_cidrs     = []

# Encryption Configuration
enable_encryption = true
kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

# Logging Configuration
enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

# IAM Configuration
create_cluster_role = true
create_node_role    = true

# IRSA Configuration
enable_irsa = true

# Node Groups Configuration
node_groups = {
  default = {
    desired_size   = 2
    max_size       = 4
    min_size       = 1
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    update_config = {
      max_unavailable = 1
    }
    labels = {
      role        = "general"
      environment = "dev"
    }
  }
}

# Additional Tags
tags = {
  Application = "platform-services"
  CostCenter  = "engineering"
}

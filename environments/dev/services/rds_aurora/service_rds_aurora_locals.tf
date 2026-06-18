locals {
  # Environment-specific configuration
  environment = "dev"

  # Resource naming prefix
  resource_prefix = "dev-rds-aurora"

  # Common tags for the dev environment
  common_dev_tags = {
    Project    = "aurora-rds"
    ManagedBy  = "Terraform"
    CostCenter = "platform"
  }
}

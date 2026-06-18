locals {
  # Common tags for all certificate resources in dev environment
  certificate_tags = {
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
    Service     = "certificatemanager"
    ManagedBy   = "Terraform"
  }
}

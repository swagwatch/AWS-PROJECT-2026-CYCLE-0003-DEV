locals {
  environment = "dev"
  owner       = "platform-team"

  common_tags = {
    Environment = local.environment
    Owner       = local.owner
    ManagedBy   = "Terraform"
  }
}

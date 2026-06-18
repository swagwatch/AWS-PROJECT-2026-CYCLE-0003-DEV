locals {
  # Merge default tags with user-provided tags
  default_tags = {
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Module      = "wafandshield"
  }

  tags = merge(local.default_tags, var.tags)
}

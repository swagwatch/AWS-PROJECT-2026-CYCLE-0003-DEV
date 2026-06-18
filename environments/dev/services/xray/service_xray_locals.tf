locals {
  # Environment-specific tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Owner       = "platform-team"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  # Custom sampling rules for dev environment
  custom_sampling_rules = var.sampling_rules

  # X-Ray groups for dev environment
  xray_groups = var.xray_groups
}

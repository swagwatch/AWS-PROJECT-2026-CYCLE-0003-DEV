locals {
  # Merge common tags with user-provided tags
  common_tags = merge(
    {
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    },
    var.project != "" ? { Project = var.project } : {},
    var.tags
  )

  # Origin Access Control name (if creating)
  oac_name = var.create_origin_access_control && var.origin_access_control_name != "" ? var.origin_access_control_name : "${var.environment}-cloudfront-oac"
}

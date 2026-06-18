locals {
  # Merge provided tags with required tags
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  )

  # Sanitized cluster identifier
  cluster_identifier_normalized = lower(replace(var.cluster_identifier, "_", "-"))

  # Final snapshot identifier with timestamp
  final_snapshot_identifier = var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${local.cluster_identifier_normalized}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Enhanced monitoring configuration
  enable_enhanced_monitoring = var.monitoring_interval > 0
  create_monitoring_role     = local.enable_enhanced_monitoring && var.monitoring_role_arn == null

  # Conditional password management
  use_managed_password = var.manage_master_user_password
  use_master_password  = !var.manage_master_user_password && var.master_password != null
}

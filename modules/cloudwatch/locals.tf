locals {
  # Merge common tags with resource-specific tags
  default_tags = merge(
    var.common_tags,
    {
      ManagedBy = "Terraform"
      Module    = "cloudwatch"
    }
  )
}

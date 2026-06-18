locals {
  # Merge default tags with user-provided tags
  tags = merge(
    {
      ManagedBy = "Terraform"
      Module    = "certificatemanager"
    },
    var.tags
  )
}

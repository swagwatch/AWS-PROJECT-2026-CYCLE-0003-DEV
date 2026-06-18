locals {
  # Merge input tags with default tags
  merged_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )

  # Use the bucket name as provided
  bucket_name = var.bucket_name

  # Determine if lifecycle configuration should be created
  has_lifecycle_rules = length(var.lifecycle_rules) > 0

  # Determine if logging should be enabled
  has_logging = var.logging_configuration != null

  # Determine if bucket policy should be created
  has_bucket_policy = var.bucket_policy != null
}

locals {
  # Environment-specific configuration
  environment = "dev"

  # Construct logging configuration if target bucket is specified
  logging_config = var.logging_target_bucket != null ? {
    target_bucket = var.logging_target_bucket
    target_prefix = var.logging_target_prefix != null ? var.logging_target_prefix : "s3-logs/"
  } : null

  # Construct encryption configuration
  encryption_config = {
    type       = var.encryption_type
    kms_key_id = var.kms_key_id
  }
}

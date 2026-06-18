module "s3_bucket" {
  source = "../../modules/s3"

  bucket_name = var.bucket_name

  encryption_configuration = local.encryption_config

  versioning_enabled = var.versioning_enabled

  public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  lifecycle_rules = var.lifecycle_rules

  logging_configuration = local.logging_config

  force_destroy = false

  tags = var.tags
}

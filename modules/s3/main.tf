# Main S3 bucket resource
resource "aws_s3_bucket" "this" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  # Object lock can only be enabled at bucket creation
  object_lock_enabled = var.object_lock_enabled

  tags = local.merged_tags
}

# Versioning configuration (separate resource in AWS provider v5.x)
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Server-side encryption configuration (separate resource in AWS provider v5.x)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_configuration.type
      kms_master_key_id = var.encryption_configuration.type == "aws:kms" ? var.encryption_configuration.kms_key_id : null
    }
  }
}

# Public access block configuration (separate resource in AWS provider v5.x)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.public_access_block.block_public_acls
  block_public_policy     = var.public_access_block.block_public_policy
  ignore_public_acls      = var.public_access_block.ignore_public_acls
  restrict_public_buckets = var.public_access_block.restrict_public_buckets
}

# Lifecycle configuration (separate resource in AWS provider v5.x, conditional)
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = local.has_lifecycle_rules ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = rule.value.prefix != null || rule.value.tags != null ? [1] : []
        content {
          and {
            prefix = rule.value.prefix
            tags   = rule.value.tags
          }
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions != null ? rule.value.noncurrent_version_transitions : []
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }
    }
  }
}

# Access logging configuration (separate resource in AWS provider v5.x, conditional)
resource "aws_s3_bucket_logging" "this" {
  count = local.has_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_configuration.target_bucket
  target_prefix = var.logging_configuration.target_prefix
}

# Bucket policy (conditional)
resource "aws_s3_bucket_policy" "this" {
  count = local.has_bucket_policy ? 1 : 0

  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy
}

# AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "this" {
  name                    = var.name
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
  policy                  = var.policy

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = local.merged_tags
}

# AWS Secrets Manager Secret Version (if secret value is provided)
resource "aws_secretsmanager_secret_version" "this" {
  count = var.secret_string != null || var.secret_binary != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
  secret_binary = var.secret_binary
}

# AWS Secrets Manager Secret Rotation
resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.rotation_enabled ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }

  depends_on = [aws_secretsmanager_secret_version.this]
}


# Example database credentials secret
module "database_credentials" {
  source = "../../modules/secretsmanager"

  name        = "dev-database-credentials"
  description = "Database credentials for application"
  kms_key_id  = var.kms_key_id

  rotation_enabled    = true
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_days       = 30

  recovery_window_in_days = 30

  tags = merge(local.common_tags, {
    Application = "database"
    Criticality = "high"
  })
}

# Example API key secret
module "api_key" {
  source = "../../modules/secretsmanager"

  name        = "dev-api-key"
  description = "API key for external service integration"
  kms_key_id  = var.kms_key_id

  rotation_enabled    = true
  rotation_lambda_arn = var.rotation_lambda_arn
  rotation_days       = 90

  recovery_window_in_days = 30

  tags = merge(local.common_tags, {
    Application = "api-integration"
    Criticality = "medium"
  })
}

# Example application secret without rotation
module "app_config" {
  source = "../../modules/secretsmanager"

  name        = "dev-app-config"
  description = "Application configuration secrets"
  kms_key_id  = var.kms_key_id

  rotation_enabled = false

  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Application = "app-config"
    Criticality = "low"
  })
}

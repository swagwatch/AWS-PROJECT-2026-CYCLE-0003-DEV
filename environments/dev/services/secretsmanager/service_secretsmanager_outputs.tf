output "database_credentials_arn" {
  description = "ARN of the database credentials secret"
  value       = module.database_credentials.secret_arn
}

output "database_credentials_id" {
  description = "ID of the database credentials secret"
  value       = module.database_credentials.secret_id
}

output "api_key_arn" {
  description = "ARN of the API key secret"
  value       = module.api_key.secret_arn
}

output "api_key_id" {
  description = "ID of the API key secret"
  value       = module.api_key.secret_id
}

output "app_config_arn" {
  description = "ARN of the app config secret"
  value       = module.app_config.secret_arn
}

output "app_config_id" {
  description = "ID of the app config secret"
  value       = module.app_config.secret_id
}

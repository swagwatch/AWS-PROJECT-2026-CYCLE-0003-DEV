# Sampling Rule Outputs
output "sampling_rule_ids" {
  description = "Map of sampling rule names to their IDs"
  value       = { for k, v in aws_xray_sampling_rule.this : k => v.id }
}

output "sampling_rule_arns" {
  description = "Map of sampling rule names to their ARNs"
  value       = { for k, v in aws_xray_sampling_rule.this : k => v.arn }
}

output "sampling_rules" {
  description = "Map of all sampling rule attributes"
  value       = aws_xray_sampling_rule.this
}

# Encryption Configuration Outputs
output "encryption_config_id" {
  description = "ID of the encryption configuration"
  value       = try(aws_xray_encryption_config.this[0].id, null)
}

output "encryption_type" {
  description = "Type of encryption configured"
  value       = try(aws_xray_encryption_config.this[0].type, null)
}

output "encryption_key_id" {
  description = "KMS key ID used for encryption"
  value       = try(aws_xray_encryption_config.this[0].key_id, null)
}

# X-Ray Group Outputs
output "group_ids" {
  description = "Map of group names to their IDs"
  value       = { for k, v in aws_xray_group.this : k => v.id }
}

output "group_arns" {
  description = "Map of group names to their ARNs"
  value       = { for k, v in aws_xray_group.this : k => v.arn }
}

output "xray_groups" {
  description = "Map of all X-Ray group attributes"
  value       = aws_xray_group.this
}

# General Outputs
output "tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

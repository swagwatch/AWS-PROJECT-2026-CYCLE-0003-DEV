output "sampling_rule_ids" {
  description = "Map of sampling rule names to their IDs"
  value       = module.xray.sampling_rule_ids
}

output "sampling_rule_arns" {
  description = "Map of sampling rule names to their ARNs"
  value       = module.xray.sampling_rule_arns
}

output "encryption_config_id" {
  description = "ID of the encryption configuration"
  value       = module.xray.encryption_config_id
}

output "encryption_type" {
  description = "Type of encryption configured"
  value       = module.xray.encryption_type
}

output "group_ids" {
  description = "Map of group names to their IDs"
  value       = module.xray.group_ids
}

output "group_arns" {
  description = "Map of group names to their ARNs"
  value       = module.xray.group_arns
}

output "tags" {
  description = "Common tags applied to all resources"
  value       = module.xray.tags
}

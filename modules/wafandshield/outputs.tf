output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "The name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "The capacity units used by the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.capacity
}

output "web_acl_tags" {
  description = "The tags applied to the WAF Web ACL"
  value       = aws_wafv2_web_acl.this.tags_all
}

output "shield_protection_id" {
  description = "The ID of the Shield protection (if enabled)"
  value       = var.enable_shield_protection && var.shield_resource_arn != "" ? aws_shield_protection.this[0].id : null
}

output "shield_protection_arn" {
  description = "The ARN of the Shield protection (if enabled)"
  value       = var.enable_shield_protection && var.shield_resource_arn != "" ? aws_shield_protection.this[0].arn : null
}

output "visibility_config" {
  description = "The visibility configuration of the WAF Web ACL"
  value = {
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled
    metric_name                = var.visibility_config.metric_name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled
  }
}

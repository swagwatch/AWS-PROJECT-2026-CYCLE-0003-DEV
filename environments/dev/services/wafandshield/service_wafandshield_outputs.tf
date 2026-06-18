output "wafandshield_web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = module.wafandshield.web_acl_id
}

output "wafandshield_web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = module.wafandshield.web_acl_arn
}

output "wafandshield_web_acl_name" {
  description = "The name of the WAF Web ACL"
  value       = module.wafandshield.web_acl_name
}

output "wafandshield_web_acl_capacity" {
  description = "The capacity units used by the WAF Web ACL"
  value       = module.wafandshield.web_acl_capacity
}

variable "name" {
  description = "Name of the WAF Web ACL"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "Name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "scope" {
  description = "Scope of the WAF Web ACL. Valid values are REGIONAL or CLOUDFRONT."
  type        = string

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "description" {
  description = "Description of the WAF Web ACL"
  type        = string
  default     = ""
}

variable "rules" {
  description = "List of rules to add to the Web ACL"
  type = list(object({
    name     = string
    priority = number
    action   = string
    statement = object({
      managed_rule_group_statement = optional(object({
        vendor_name = string
        name        = string
      }))
      rate_based_statement = optional(object({
        limit              = number
        aggregate_key_type = string
      }))
      geo_match_statement = optional(object({
        country_codes = list(string)
      }))
    })
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  }))
  default = []
}

variable "default_action" {
  description = "Default action for the Web ACL. Valid values are 'allow' or 'block'."
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either 'allow' or 'block'."
  }
}

variable "visibility_config" {
  description = "Visibility configuration for the Web ACL"
  type = object({
    cloudwatch_metrics_enabled = bool
    metric_name                = string
    sampled_requests_enabled   = bool
  })
  default = {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metrics"
    sampled_requests_enabled   = true
  }
}

variable "enable_shield_protection" {
  description = "Enable AWS Shield Advanced protection"
  type        = bool
  default     = false
}

variable "shield_resource_arn" {
  description = "ARN of the resource to protect with Shield (required if enable_shield_protection is true)"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for the resource"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

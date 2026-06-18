variable "waf_scope" {
  description = "Scope of the WAF Web ACL (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "REGIONAL"
}

variable "waf_description" {
  description = "Description of the WAF Web ACL"
  type        = string
  default     = "Development environment WAF for application protection"
}

variable "enable_shield" {
  description = "Enable AWS Shield Advanced protection"
  type        = bool
  default     = false
}

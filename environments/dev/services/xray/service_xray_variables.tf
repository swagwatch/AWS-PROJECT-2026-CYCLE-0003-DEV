variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "xray-demo"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "sampling_rules" {
  description = "List of X-Ray sampling rules"
  type = list(object({
    rule_name      = string
    priority       = number
    fixed_rate     = number
    reservoir_size = number
    url_path       = optional(string, "*")
    host           = optional(string, "*")
    http_method    = optional(string, "*")
    service_name   = optional(string, "*")
    service_type   = optional(string, "*")
    resource_arn   = optional(string, "*")
    version        = optional(number, 1)
    attributes     = optional(map(string), {})
  }))
  default = []
}

variable "encryption_enabled" {
  description = "Enable encryption for X-Ray data"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Type of encryption (KMS or NONE)"
  type        = string
  default     = "KMS"
}

variable "encryption_key_id" {
  description = "KMS key ID for X-Ray encryption"
  type        = string
  default     = null
}

variable "xray_groups" {
  description = "List of X-Ray groups"
  type = list(object({
    group_name        = string
    filter_expression = string
    insights_enabled  = optional(bool, false)
  }))
  default = []
}

variable "create_default_sampling_rule" {
  description = "Create a default sampling rule"
  type        = bool
  default     = true
}

variable "default_sampling_rate" {
  description = "Default sampling rate"
  type        = number
  default     = 0.05
}

variable "default_reservoir_size" {
  description = "Default reservoir size"
  type        = number
  default     = 1
}

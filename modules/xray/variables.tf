variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources. Must include Environment and Owner."
  type        = map(string)
  default     = {}
}

# Sampling Rule Configuration
variable "sampling_rules" {
  description = "List of X-Ray sampling rules to create"
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

  validation {
    condition = alltrue([
      for rule in var.sampling_rules : rule.fixed_rate >= 0 && rule.fixed_rate <= 1
    ])
    error_message = "Sampling fixed_rate must be between 0 and 1."
  }

  validation {
    condition = alltrue([
      for rule in var.sampling_rules : rule.reservoir_size >= 0
    ])
    error_message = "Reservoir size must be non-negative."
  }

  validation {
    condition = alltrue([
      for rule in var.sampling_rules : rule.priority >= 1 && rule.priority <= 9999
    ])
    error_message = "Sampling rule priority must be between 1 and 9999."
  }
}

# Encryption Configuration
variable "encryption_enabled" {
  description = "Enable encryption for X-Ray data"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Type of encryption (KMS or NONE)"
  type        = string
  default     = "KMS"

  validation {
    condition     = contains(["KMS", "NONE"], var.encryption_type)
    error_message = "Encryption type must be either KMS or NONE."
  }
}

variable "encryption_key_id" {
  description = "KMS key ID for X-Ray encryption (only used when encryption_type is KMS)"
  type        = string
  default     = null
}

# X-Ray Group Configuration
variable "xray_groups" {
  description = "List of X-Ray groups to create"
  type = list(object({
    group_name        = string
    filter_expression = string
    insights_enabled  = optional(bool, false)
  }))
  default = []
}

# Feature Flags
variable "create_default_sampling_rule" {
  description = "Create a default sampling rule"
  type        = bool
  default     = true
}

variable "default_sampling_rate" {
  description = "Default sampling rate (0.0 to 1.0)"
  type        = number
  default     = 0.05

  validation {
    condition     = var.default_sampling_rate >= 0 && var.default_sampling_rate <= 1
    error_message = "Default sampling rate must be between 0 and 1."
  }
}

variable "default_reservoir_size" {
  description = "Default reservoir size for sampling"
  type        = number
  default     = 1

  validation {
    condition     = var.default_reservoir_size >= 0
    error_message = "Default reservoir size must be non-negative."
  }
}

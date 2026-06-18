variable "name" {
  description = "Name of the secret. Must be unique within the AWS account and region."
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 512
    error_message = "Secret name must be between 1 and 512 characters."
  }
}

variable "description" {
  description = "Human-readable description of the secret."
  type        = string
  default     = null
}

variable "kms_key_id" {
  description = "ARN or ID of the KMS key to use for encryption. If not specified, uses AWS managed key (not recommended for production)."
  type        = string
  default     = null
}

variable "recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before deleting the secret. Set to 0 for immediate deletion (not recommended)."
  type        = number
  default     = 30

  validation {
    condition     = var.recovery_window_in_days >= 0 && var.recovery_window_in_days <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}

variable "tags" {
  description = "Map of tags to assign to the secret."
  type        = map(string)
  default     = {}
}

variable "rotation_enabled" {
  description = "Whether to enable automatic rotation for this secret."
  type        = bool
  default     = false
}

variable "rotation_lambda_arn" {
  description = "ARN of the Lambda function that performs the rotation. Required if rotation_enabled is true."
  type        = string
  default     = null
}

variable "rotation_days" {
  description = "Number of days between automatic rotations."
  type        = number
  default     = 30

  validation {
    condition     = var.rotation_days >= 1 && var.rotation_days <= 1000
    error_message = "Rotation days must be between 1 and 1000."
  }
}

variable "secret_string" {
  description = "Initial secret value as a string (e.g., JSON-encoded credentials)."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_binary" {
  description = "Initial secret value as binary (base64-encoded)."
  type        = string
  default     = null
  sensitive   = true
}

variable "policy" {
  description = "Resource-based policy JSON for the secret."
  type        = string
  default     = null
}

variable "replica_regions" {
  description = "List of regions to replicate the secret to, with optional KMS key per region."
  type = list(object({
    region     = string
    kms_key_id = optional(string)
  }))
  default = []
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "encryption_type" {
  description = "Encryption type (AES256 or aws:kms)"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID for SSE-KMS encryption"
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Enable versioning"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    id      = string
    enabled = bool
    prefix  = optional(string)
    tags    = optional(map(string))

    expiration = optional(object({
      days = number
    }))

    transitions = optional(list(object({
      days          = number
      storage_class = string
    })))

    noncurrent_version_expiration = optional(object({
      days = number
    }))

    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })))
  }))
  default = []
}

variable "logging_target_bucket" {
  description = "Target bucket for access logs"
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags for the bucket"
  type        = map(string)
}

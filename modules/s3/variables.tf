variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string
}

variable "encryption_configuration" {
  description = "Server-side encryption configuration for the bucket"
  type = object({
    type       = string
    kms_key_id = optional(string)
  })
  default = {
    type = "AES256"
  }

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_configuration.type)
    error_message = "Encryption type must be either 'AES256' (SSE-S3) or 'aws:kms' (SSE-KMS)"
  }
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "public_access_block" {
  description = "Public access block configuration for the bucket"
  type = object({
    block_public_acls       = bool
    block_public_policy     = bool
    ignore_public_acls      = bool
    restrict_public_buckets = bool
  })
  default = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
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

variable "tags" {
  description = "Tags to apply to the S3 bucket (must include Environment and Owner)"
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Environment") && contains(keys(var.tags), "Owner")
    error_message = "Tags must include 'Environment' and 'Owner' keys"
  }
}

variable "logging_configuration" {
  description = "Access logging configuration for the bucket"
  type = object({
    target_bucket = string
    target_prefix = string
  })
  default = null
}

variable "force_destroy" {
  description = "Allow deletion of non-empty bucket"
  type        = bool
  default     = false
}

variable "object_lock_enabled" {
  description = "Enable object lock for compliance requirements"
  type        = bool
  default     = false
}

variable "bucket_policy" {
  description = "Optional bucket policy JSON"
  type        = string
  default     = null
}

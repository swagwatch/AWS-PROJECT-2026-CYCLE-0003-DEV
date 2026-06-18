variable "name" {
  description = "The name of the SNS topic"
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "The owner of the SNS topic for tagging"
  type        = string
}

variable "fifo_topic" {
  description = "Boolean indicating whether this is a FIFO topic"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO topics"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "The ID or ARN of the AWS KMS key to use for encryption at rest"
  type        = string
  default     = null
}

variable "display_name" {
  description = "The display name for the SNS topic"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "The SNS delivery policy as a JSON string"
  type        = string
  default     = null
}

variable "policy" {
  description = "The fully-formed AWS policy as a JSON string"
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "subscriptions" {
  description = "List of SNS topic subscriptions"
  type = list(object({
    protocol                        = string
    endpoint                        = string
    filter_policy                   = optional(string)
    raw_message_delivery            = optional(bool)
    confirmation_timeout_in_minutes = optional(number)
  }))
  default = []
}

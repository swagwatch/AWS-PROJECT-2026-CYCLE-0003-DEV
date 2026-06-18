variable "queue_name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = "The visibility timeout for the queue"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "The number of seconds Amazon SQS retains a message"
  type        = number
  default     = 345600
}

variable "dlq_arn" {
  description = "The ARN of the dead-letter queue"
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "The number of times a message is delivered before being moved to DLQ"
  type        = number
  default     = 5
}

variable "tags" {
  description = "A map of tags to assign to the queue"
  type        = map(string)
  default     = {}
}

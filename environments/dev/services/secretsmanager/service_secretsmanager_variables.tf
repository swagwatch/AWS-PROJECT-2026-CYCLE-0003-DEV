variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "kms_key_id" {
  description = "KMS key ID for secret encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}

variable "rotation_lambda_arn" {
  description = "Lambda ARN for secret rotation"
  type        = string
  default     = "arn:aws:lambda:us-east-1:123456789012:function:secret-rotation"
}

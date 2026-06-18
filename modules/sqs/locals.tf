locals {
  # Append .fifo suffix for FIFO queues
  queue_name_with_suffix = var.fifo_queue ? "${var.queue_name}.fifo" : var.queue_name

  # Merge input tags with module metadata
  merged_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "sqs"
    }
  )

  # Conditional redrive policy - only set if DLQ ARN is provided
  redrive_policy = var.dlq_arn != null ? jsonencode({
    deadLetterTargetArn = var.dlq_arn
    maxReceiveCount     = var.max_receive_count
  }) : null
}

resource "aws_sqs_queue" "this" {
  name                              = local.queue_name_with_suffix
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.content_based_deduplication
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_data_key_reuse_period_seconds
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  message_retention_seconds         = var.message_retention_seconds
  max_message_size                  = var.max_message_size
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  delay_seconds                     = var.delay_seconds
  redrive_policy                    = local.redrive_policy

  tags = local.merged_tags
}

resource "aws_sqs_queue_policy" "this" {
  count = var.queue_policy != null ? 1 : 0

  queue_url = aws_sqs_queue.this.url
  policy    = var.queue_policy
}

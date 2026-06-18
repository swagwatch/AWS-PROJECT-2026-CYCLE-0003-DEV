module "sqs" {
  source = "../../modules/sqs"

  queue_name                 = var.queue_name
  fifo_queue                 = var.fifo_queue
  kms_master_key_id          = var.kms_master_key_id
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  dlq_arn                    = var.dlq_arn
  max_receive_count          = var.max_receive_count
  tags                       = local.merged_tags
}

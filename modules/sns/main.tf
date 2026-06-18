resource "aws_sns_topic" "this" {
  name                        = local.topic_name
  display_name                = var.display_name
  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic ? var.content_based_deduplication : null
  kms_master_key_id           = var.kms_master_key_id
  delivery_policy             = var.delivery_policy

  tags = local.merged_tags
}

resource "aws_sns_topic_policy" "this" {
  count = var.policy != null ? 1 : 0

  arn    = aws_sns_topic.this.arn
  policy = var.policy
}

resource "aws_sns_topic_subscription" "this" {
  count = length(var.subscriptions)

  topic_arn                       = aws_sns_topic.this.arn
  protocol                        = var.subscriptions[count.index].protocol
  endpoint                        = var.subscriptions[count.index].endpoint
  filter_policy                   = var.subscriptions[count.index].filter_policy
  raw_message_delivery            = var.subscriptions[count.index].raw_message_delivery
  confirmation_timeout_in_minutes = var.subscriptions[count.index].confirmation_timeout_in_minutes
}

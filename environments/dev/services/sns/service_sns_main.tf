module "sns_topic" {
  source = "../../modules/sns"

  name        = var.name
  environment = var.environment
  owner       = var.owner

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.content_based_deduplication
  kms_master_key_id           = var.kms_master_key_id
  display_name                = var.display_name
  delivery_policy             = var.delivery_policy
  policy                      = var.policy

  tags = var.tags

  subscriptions = var.subscriptions
}

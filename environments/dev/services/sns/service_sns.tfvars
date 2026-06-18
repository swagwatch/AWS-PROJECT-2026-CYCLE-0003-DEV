name        = "notifications"
environment = "dev"
owner       = "platform-team"

fifo_topic                  = false
content_based_deduplication = false
kms_master_key_id           = "alias/dev-sns-key"
display_name                = "Dev Notifications Topic"
delivery_policy             = "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20,\"numRetries\":3,\"numMaxDelayRetries\":0,\"numNoDelayRetries\":0,\"numMinDelayRetries\":0,\"backoffFunction\":\"linear\"}}}"

tags = {
  Project   = "core-infrastructure"
  ManagedBy = "terraform"
}

subscriptions = []

queue_name                 = "dev-example-queue"
fifo_queue                 = false
kms_master_key_id          = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
visibility_timeout_seconds = 30
message_retention_seconds  = 345600
max_receive_count          = 5
tags = {
  Environment = "dev"
  Owner       = "platform-team"
  Service     = "sqs"
}

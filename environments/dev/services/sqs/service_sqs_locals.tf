locals {
  merged_tags = merge(
    var.tags,
    {
      Environment = "dev"
      Owner       = "platform-team"
      Service     = "sqs"
    }
  )
}

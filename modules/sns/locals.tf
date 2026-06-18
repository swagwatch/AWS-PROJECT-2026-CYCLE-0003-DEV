locals {
  # Construct topic name with FIFO suffix if needed
  topic_name = var.fifo_topic ? "${var.name}.fifo" : var.name

  # Merge default required tags with custom tags
  default_tags = {
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }

  merged_tags = merge(local.default_tags, var.tags)
}

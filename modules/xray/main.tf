# AWS X-Ray Sampling Rules
resource "aws_xray_sampling_rule" "this" {
  for_each = { for rule in local.all_sampling_rules : rule.rule_name => rule }

  rule_name      = each.value.rule_name
  priority       = each.value.priority
  version        = each.value.version
  reservoir_size = each.value.reservoir_size
  fixed_rate     = each.value.fixed_rate
  url_path       = each.value.url_path
  host           = each.value.host
  http_method    = each.value.http_method
  service_type   = each.value.service_type
  service_name   = each.value.service_name
  resource_arn   = each.value.resource_arn
  attributes     = each.value.attributes

  tags = local.common_tags
}

# AWS X-Ray Encryption Configuration
resource "aws_xray_encryption_config" "this" {
  count = local.encryption_config != null ? 1 : 0

  type   = local.encryption_config.type
  key_id = local.encryption_config.key_id
}

# AWS X-Ray Groups
resource "aws_xray_group" "this" {
  for_each = { for group in var.xray_groups : group.group_name => group }

  group_name        = each.value.group_name
  filter_expression = each.value.filter_expression

  dynamic "insights_configuration" {
    for_each = each.value.insights_enabled ? [1] : []
    content {
      insights_enabled      = true
      notifications_enabled = false
    }
  }

  tags = local.common_tags
}

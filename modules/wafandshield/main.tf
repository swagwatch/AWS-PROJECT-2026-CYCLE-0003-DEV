resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  description = var.description

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement.managed_rule_group_statement != null ? [rule.value.statement.managed_rule_group_statement] : []
          content {
            vendor_name = managed_rule_group_statement.value.vendor_name
            name        = managed_rule_group_statement.value.name
          }
        }

        dynamic "rate_based_statement" {
          for_each = rule.value.statement.rate_based_statement != null ? [rule.value.statement.rate_based_statement] : []
          content {
            limit              = rate_based_statement.value.limit
            aggregate_key_type = rate_based_statement.value.aggregate_key_type
          }
        }

        dynamic "geo_match_statement" {
          for_each = rule.value.statement.geo_match_statement != null ? [rule.value.statement.geo_match_statement] : []
          content {
            country_codes = geo_match_statement.value.country_codes
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name                = rule.value.visibility_config.metric_name
        sampled_requests_enabled   = rule.value.visibility_config.sampled_requests_enabled
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled
    metric_name                = var.visibility_config.metric_name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled
  }

  tags = local.tags
}

resource "aws_shield_protection" "this" {
  count = var.enable_shield_protection && var.shield_resource_arn != "" ? 1 : 0

  name         = "${var.name}-shield"
  resource_arn = var.shield_resource_arn

  tags = local.tags
}

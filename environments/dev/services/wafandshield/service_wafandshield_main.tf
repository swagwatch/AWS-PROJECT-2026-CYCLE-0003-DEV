module "wafandshield" {
  source = "../../modules/wafandshield"

  name        = local.wafandshield_name
  scope       = var.waf_scope
  description = var.waf_description

  rules = [
    {
      name     = "AWSManagedRulesCommonRuleSet"
      priority = 1
      action   = "none"
      statement = {
        managed_rule_group_statement = {
          vendor_name = "AWS"
          name        = "AWSManagedRulesCommonRuleSet"
        }
        rate_based_statement = null
        geo_match_statement  = null
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "RateLimitRule"
      priority = 2
      action   = "count"
      statement = {
        managed_rule_group_statement = null
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
        geo_match_statement = null
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitRule"
        sampled_requests_enabled   = true
      }
    }
  ]

  default_action = "allow"

  visibility_config = {
    cloudwatch_metrics_enabled = true
    metric_name                = "${replace(local.wafandshield_name, "-", "_")}_metrics"
    sampled_requests_enabled   = true
  }

  enable_shield_protection = var.enable_shield
  shield_resource_arn      = ""

  environment = local.environment
  owner       = local.owner

  tags = local.common_tags
}

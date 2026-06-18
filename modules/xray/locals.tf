locals {
  # Common tags merged with user-provided tags
  common_tags = merge(
    var.tags,
    {
      Module      = "xray"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  )

  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Default sampling rule configuration
  default_sampling_rule = var.create_default_sampling_rule ? [{
    rule_name      = "${local.name_prefix}-default-sampling"
    priority       = 9999
    fixed_rate     = var.default_sampling_rate
    reservoir_size = var.default_reservoir_size
    url_path       = "*"
    host           = "*"
    http_method    = "*"
    service_name   = "*"
    service_type   = "*"
    resource_arn   = "*"
    version        = 1
    attributes     = {}
  }] : []

  # Combine custom sampling rules with default
  all_sampling_rules = concat(var.sampling_rules, local.default_sampling_rule)

  # Encryption configuration
  encryption_config = var.encryption_enabled ? {
    type   = var.encryption_type
    key_id = var.encryption_type == "KMS" ? var.encryption_key_id : null
  } : null
}

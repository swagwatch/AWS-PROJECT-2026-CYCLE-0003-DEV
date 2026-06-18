module "xray" {
  source = "../../modules/xray"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.common_tags

  # Sampling Rules Configuration
  sampling_rules               = local.custom_sampling_rules
  create_default_sampling_rule = var.create_default_sampling_rule
  default_sampling_rate        = var.default_sampling_rate
  default_reservoir_size       = var.default_reservoir_size

  # Encryption Configuration
  encryption_enabled = var.encryption_enabled
  encryption_type    = var.encryption_type
  encryption_key_id  = var.encryption_key_id

  # X-Ray Groups Configuration
  xray_groups = local.xray_groups
}

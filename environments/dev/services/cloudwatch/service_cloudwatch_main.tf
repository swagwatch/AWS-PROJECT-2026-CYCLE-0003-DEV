module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment = var.environment

  log_groups    = var.cloudwatch_log_groups
  metric_alarms = var.cloudwatch_metric_alarms
  common_tags   = var.cloudwatch_tags
}

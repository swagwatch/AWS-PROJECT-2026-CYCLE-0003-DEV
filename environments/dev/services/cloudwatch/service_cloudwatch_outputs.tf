output "cloudwatch_log_group_arns" {
  description = "ARNs of the CloudWatch Log Groups"
  value       = module.cloudwatch.log_group_arns
}

output "cloudwatch_log_group_names" {
  description = "Names of the CloudWatch Log Groups"
  value       = module.cloudwatch.log_group_names
}

output "cloudwatch_metric_alarm_arns" {
  description = "ARNs of the CloudWatch Metric Alarms"
  value       = module.cloudwatch.metric_alarm_arns
}

output "cloudwatch_metric_alarm_ids" {
  description = "IDs of the CloudWatch Metric Alarms"
  value       = module.cloudwatch.metric_alarm_ids
}

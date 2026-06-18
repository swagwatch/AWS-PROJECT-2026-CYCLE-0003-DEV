# Log Group Outputs
output "log_group_arns" {
  description = "ARNs of the CloudWatch Log Groups"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.arn }
}

output "log_group_names" {
  description = "Names of the CloudWatch Log Groups"
  value       = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}

# Metric Alarm Outputs
output "metric_alarm_arns" {
  description = "ARNs of the CloudWatch Metric Alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "metric_alarm_ids" {
  description = "IDs of the CloudWatch Metric Alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.id }
}

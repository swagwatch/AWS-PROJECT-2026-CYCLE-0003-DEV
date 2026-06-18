cloudwatch_log_groups = {
  "/aws/application/dev-app" = {
    retention_in_days = 30
    kms_key_id        = null
  }
  "/aws/lambda/dev-functions" = {
    retention_in_days = 14
    kms_key_id        = null
  }
}

cloudwatch_metric_alarms = {
  "dev-high-cpu-alarm" = {
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 80
    alarm_description   = "Triggers when CPU utilization exceeds 80%"
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:dev-alerts"]
  }
  "dev-high-memory-alarm" = {
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 3
    metric_name         = "MemoryUtilization"
    namespace           = "AWS/EC2"
    period              = 300
    statistic           = "Average"
    threshold           = 85
    alarm_description   = "Triggers when memory utilization exceeds 85%"
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:dev-alerts"]
  }
}

cloudwatch_tags = {
  Environment = "dev"
  Owner       = "platform-team"
  Project     = "cloudwatch-module"
}

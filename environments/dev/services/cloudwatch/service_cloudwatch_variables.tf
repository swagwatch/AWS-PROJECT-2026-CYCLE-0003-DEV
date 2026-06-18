variable "cloudwatch_log_groups" {
  description = "Map of CloudWatch Log Group configurations"
  type = map(object({
    retention_in_days = number
    kms_key_id        = optional(string)
  }))
}

variable "cloudwatch_metric_alarms" {
  description = "Map of CloudWatch Metric Alarm configurations"
  type = map(object({
    comparison_operator       = string
    evaluation_periods        = number
    metric_name               = string
    namespace                 = string
    period                    = number
    statistic                 = string
    threshold                 = number
    alarm_description         = optional(string)
    alarm_actions             = optional(list(string), [])
    ok_actions                = optional(list(string), [])
    insufficient_data_actions = optional(list(string), [])
    treat_missing_data        = optional(string, "missing")
    datapoints_to_alarm       = optional(number)
    dimensions                = optional(map(string), {})
  }))
}

variable "cloudwatch_tags" {
  description = "Tags to apply to CloudWatch resources"
  type        = map(string)
}

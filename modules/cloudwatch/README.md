# AWS CloudWatch Terraform Module

This module provisions and manages AWS CloudWatch resources including Log Groups and Metric Alarms.

## Features

- Create CloudWatch Log Groups with configurable retention policies
- Create CloudWatch Metric Alarms with customizable thresholds and actions
- Automatic tagging of all resources
- KMS encryption support for log groups
- OPA policy validation for security and compliance

## Resources Created

- `aws_cloudwatch_log_group` - CloudWatch Log Groups for application and infrastructure logging
- `aws_cloudwatch_metric_alarm` - CloudWatch Metric Alarms for monitoring and alerting

## Usage

```hcl
module "cloudwatch" {
  source = "../../modules/cloudwatch"

  environment = "dev"

  log_groups = {
    "/aws/application/app" = {
      retention_in_days = 30
      kms_key_id        = null
    }
    "/aws/lambda/functions" = {
      retention_in_days = 14
      kms_key_id        = null
    }
  }

  metric_alarms = {
    "high-cpu-alarm" = {
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "CPUUtilization"
      namespace           = "AWS/EC2"
      period              = 300
      statistic           = "Average"
      threshold           = 80
      alarm_description   = "Triggers when CPU utilization exceeds 80%"
      alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:alerts"]
    }
  }

  common_tags = {
    Environment = "dev"
    Owner       = "platform-team"
    Project     = "cloudwatch-module"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., dev, staging, production) | `string` | n/a | yes |
| log_groups | Map of CloudWatch Log Group configurations | `map(object({...}))` | `{}` | no |
| metric_alarms | Map of CloudWatch Metric Alarm configurations | `map(object({...}))` | `{}` | no |
| common_tags | Common tags to apply to all CloudWatch resources | `map(string)` | `{}` | no |

### log_groups Object Structure

```hcl
{
  retention_in_days = number        # Log retention period in days
  kms_key_id        = string        # KMS key ARN for encryption (optional)
}
```

### metric_alarms Object Structure

```hcl
{
  comparison_operator       = string              # Comparison operator (e.g., GreaterThanThreshold)
  evaluation_periods        = number              # Number of periods to evaluate
  metric_name               = string              # CloudWatch metric name
  namespace                 = string              # CloudWatch namespace
  period                    = number              # Period in seconds
  statistic                 = string              # Statistic (Average, Sum, etc.)
  threshold                 = number              # Alarm threshold
  alarm_description         = string              # Description of the alarm (optional)
  alarm_actions             = list(string)        # Actions when alarm triggers (optional)
  ok_actions                = list(string)        # Actions when alarm recovers (optional)
  insufficient_data_actions = list(string)        # Actions for insufficient data (optional)
  treat_missing_data        = string              # How to treat missing data (optional)
  datapoints_to_alarm       = number              # Datapoints required to trigger (optional)
  dimensions                = map(string)         # Metric dimensions (optional)
}
```

## Outputs

| Name | Description |
|------|-------------|
| log_group_arns | ARNs of the CloudWatch Log Groups |
| log_group_names | Names of the CloudWatch Log Groups |
| metric_alarm_arns | ARNs of the CloudWatch Metric Alarms |
| metric_alarm_ids | IDs of the CloudWatch Metric Alarms |

## Security and Compliance

This module includes OPA (Open Policy Agent) policies that enforce security and compliance best practices:

### Critical Rules (Deny - Blocks Deployment)
- Log groups must have retention policies set
- Log groups must have required tags (Environment and Owner)
- Production log groups must use KMS encryption
- Metric alarms must have at least one action configured
- Metric alarms must have sufficient evaluation periods (>= 2)

### Warning Rules (Non-blocking)
- Log groups with very short retention periods (< 7 days)
- Log groups with very long retention periods (> 365 days)
- Metric alarms without alarm_actions

See the [policy README](policy/README.md) for detailed policy documentation.

## Examples

### Basic Log Group

```hcl
log_groups = {
  "/aws/application/app" = {
    retention_in_days = 30
    kms_key_id        = null
  }
}
```

### Production Log Group with Encryption

```hcl
log_groups = {
  "/aws/application/prod-app" = {
    retention_in_days = 90
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

common_tags = {
  Environment = "production"
  Owner       = "platform-team"
}
```

### CloudWatch Alarm with SNS Integration

```hcl
metric_alarms = {
  "high-error-rate" = {
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = 2
    metric_name         = "Errors"
    namespace           = "AWS/Lambda"
    period              = 300
    statistic           = "Sum"
    threshold           = 10
    alarm_description   = "Triggers when error count exceeds 10"
    alarm_actions       = ["arn:aws:sns:us-east-1:123456789012:critical-alerts"]
    ok_actions          = ["arn:aws:sns:us-east-1:123456789012:recovery-alerts"]
  }
}
```

## Notes

- Log group names must follow AWS CloudWatch naming conventions
- For production environments, KMS encryption is required by OPA policy
- Retention periods must be set to prevent indefinite log storage
- Metric alarms should have at least 2 evaluation periods to prevent flapping
- All alarm actions should be configured for the alarm to be actionable

## License

This module is maintained as part of the organization's infrastructure as code repository.

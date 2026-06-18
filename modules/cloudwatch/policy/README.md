# CloudWatch OPA Policy Documentation

This directory contains Open Policy Agent (OPA) Rego policies that validate Terraform plans for AWS CloudWatch resources. These policies enforce security, compliance, and operational best practices before infrastructure changes are deployed.

## Policy Validation Approach

The policies evaluate Terraform plan JSON output (`terraform show -json plan.tfplan`) and produce two types of findings:

- **CRITICAL (deny)**: Violations that block deployment and fail the CI/CD pipeline
- **WARNING (warn)**: Recommendations that are logged but don't block deployment

## Critical Deny Rules

These rules represent serious security or compliance violations that must be fixed before deployment:

### 1. Log Groups Must Have Retention Policies

**Rule**: `deny[violation] if log group retention is null or 0`

**Why**: Log groups without retention policies store logs indefinitely, leading to excessive storage costs and potential compliance issues.

**Example Violation**:
```
CloudWatch Log Group 'aws_cloudwatch_log_group.app_logs' must have a retention policy set.
Set retention_in_days to prevent indefinite log storage and excessive costs.
```

**How to Fix**:
```hcl
log_groups = {
  "/aws/application/app" = {
    retention_in_days = 30  # Set appropriate retention period
    kms_key_id        = null
  }
}
```

### 2. Log Groups Must Have Required Tags (Environment)

**Rule**: `deny[violation] if log group missing 'Environment' tag`

**Why**: The Environment tag is required for cost allocation, compliance tracking, and resource organization.

**Example Violation**:
```
CloudWatch Log Group 'aws_cloudwatch_log_group.app_logs' is missing required tag 'Environment'.
Add Environment tag for cost allocation and compliance.
```

**How to Fix**:
```hcl
common_tags = {
  Environment = "dev"  # or "staging", "production", etc.
  Owner       = "platform-team"
}
```

### 3. Log Groups Must Have Required Tags (Owner)

**Rule**: `deny[violation] if log group missing 'Owner' tag`

**Why**: The Owner tag is required for accountability and resource management.

**Example Violation**:
```
CloudWatch Log Group 'aws_cloudwatch_log_group.app_logs' is missing required tag 'Owner'.
Add Owner tag for accountability and resource management.
```

**How to Fix**:
```hcl
common_tags = {
  Environment = "dev"
  Owner       = "platform-team"  # Team or individual responsible
}
```

### 4. Production Log Groups Must Use KMS Encryption

**Rule**: `deny[violation] if log group Environment=production and kms_key_id is null/empty`

**Why**: Production environments require encryption at rest to protect sensitive log data and meet compliance requirements.

**Example Violation**:
```
CloudWatch Log Group 'aws_cloudwatch_log_group.prod_logs' in production environment must use KMS encryption.
Set kms_key_id to encrypt logs at rest.
```

**How to Fix**:
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

### 5. Metric Alarms Must Have Actions Configured

**Rule**: `deny[violation] if all alarm action lists (alarm_actions, ok_actions, insufficient_data_actions) are empty`

**Why**: Alarms without actions don't notify anyone and are not actionable, rendering them useless for monitoring.

**Example Violation**:
```
CloudWatch Metric Alarm 'aws_cloudwatch_metric_alarm.high_cpu' has no actions configured.
Configure alarm_actions, ok_actions, or insufficient_data_actions to make the alarm actionable.
```

**How to Fix**:
```hcl
metric_alarms = {
  "high-cpu-alarm" = {
    # ... other configuration ...
    alarm_actions = ["arn:aws:sns:us-east-1:123456789012:alerts"]
  }
}
```

### 6. Metric Alarms Must Have Sufficient Evaluation Periods

**Rule**: `deny[violation] if evaluation_periods < 2`

**Why**: Alarms with only 1 evaluation period can cause flapping alerts due to transient spikes, leading to alert fatigue.

**Example Violation**:
```
CloudWatch Metric Alarm 'aws_cloudwatch_metric_alarm.high_cpu' has evaluation_periods set to 1.
Use at least 2 evaluation periods to prevent flapping alerts.
```

**How to Fix**:
```hcl
metric_alarms = {
  "high-cpu-alarm" = {
    # ... other configuration ...
    evaluation_periods = 2  # Minimum recommended
  }
}
```

## Warning Rules

These rules provide recommendations for cost optimization and operational best practices but don't block deployment:

### 1. Short Retention Periods May Cause Data Loss

**Rule**: `warn[warning] if retention_in_days < 7 and > 0`

**Why**: Very short retention periods may not provide enough time for troubleshooting and incident investigations.

**Recommendation**: Consider using at least 7 days retention for operational logs.

### 2. Long Retention Periods May Incur Excessive Costs

**Rule**: `warn[warning] if retention_in_days > 365`

**Why**: Storing logs for more than a year in CloudWatch Logs can be expensive. Consider archiving to S3 for long-term retention.

**Recommendation**: Use CloudWatch Logs for active monitoring (< 1 year) and export to S3 for long-term archival.

### 3. Metric Alarms Without alarm_actions Won't Notify

**Rule**: `warn[warning] if alarm_actions is empty but other actions are configured`

**Why**: If you've configured ok_actions or insufficient_data_actions but not alarm_actions, you won't get notified when the alarm actually triggers.

**Recommendation**: Add SNS topic to alarm_actions for critical alerts.

## Running Policy Validation Locally

### Validate Policy Syntax

```bash
opa check modules/cloudwatch/policy/main.rego modules/cloudwatch/policy/test.rego
```

### Run Policy Unit Tests

```bash
opa test modules/cloudwatch/policy/ -v
```

Expected output: `PASS: 6/6` (all tests passing)

### Validate Terraform Plan Against Policies

```bash
# Generate Terraform plan
cd environments/dev
terraform plan -out=tfplan.binary

# Convert plan to JSON
terraform show -json tfplan.binary > tfplan.json

# Check for CRITICAL violations (exit code 0 = no violations, 1 = violations found)
opa eval -d opa-policies/service_cloudwatch_policies.rego -i tfplan.json --fail "count(data.terraform.aws.cloudwatch.deny) > 0"

# View any CRITICAL violations
opa eval -d opa-policies/service_cloudwatch_policies.rego -i tfplan.json "data.terraform.aws.cloudwatch.deny"

# View any WARNINGS
opa eval -d opa-policies/service_cloudwatch_policies.rego -i tfplan.json "data.terraform.aws.cloudwatch.warn"
```

## CI/CD Integration

These policies are automatically enforced in the CI/CD pipeline:

1. **Pre-commit Hook**: Runs on every commit attempt, validates Terraform plan against OPA policies
2. **GitHub Actions**: Runs on pull requests and merges to main branch
3. **Deployment Gates**: Blocks deployment if CRITICAL violations are found

See the root [README.md](../../../README.md) for detailed CI/CD workflow documentation.

## Policy Modification Guidelines

When modifying policies:

1. **Add tests first**: Create test cases in `test.rego` before implementing new rules
2. **Run tests**: Ensure all tests pass with `opa test modules/cloudwatch/policy/ -v`
3. **Document rules**: Update this README with clear explanations and examples
4. **Consider impact**: CRITICAL rules block deployments, use sparingly for genuine security/compliance issues
5. **Use WARNINGs liberally**: For best practices that shouldn't block deployments

## Helper Functions

The policies use these helper functions (defined in main.rego):

- `resource_changes_by_type(type)`: Returns resources being created or updated (excludes deletes)
- `get_tags(after)`: Safely extracts tags from resource, checking both `tags` and `tags_all` fields
- `array_contains(arr, value)`: Checks if an array contains a specific value

## Testing Strategy

Policy tests cover:

1. **Valid configurations**: Ensure compliant configurations produce no violations
2. **Invalid configurations**: Ensure non-compliant configurations produce expected violations
3. **Edge cases**: Deleted resources, null values, empty configurations
4. **Environment-specific rules**: Production vs non-production validation

All tests must pass before policies can be merged.

## Troubleshooting

### Policy Validation Fails in CI/CD

1. Run validation locally: `opa eval -d opa-policies/service_cloudwatch_policies.rego -i tfplan.json "data.terraform.aws.cloudwatch.deny"`
2. Review violation messages for specific issues
3. Fix the Terraform configuration based on violation guidance
4. Re-run validation until all CRITICAL violations are resolved

### Tests Fail Locally

1. Verify OPA version: `opa version` (should be compatible with Rego v1 syntax)
2. Check test file syntax: `opa check modules/cloudwatch/policy/test.rego`
3. Run tests with verbose output: `opa test modules/cloudwatch/policy/ -v`
4. Review test failure messages for specific assertion failures

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terraform AWS Provider - CloudWatch Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)
- [AWS CloudWatch Best Practices](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html)

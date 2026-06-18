# AWS X-Ray OPA Policy Documentation

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS X-Ray Terraform configurations. These policies enforce security best practices, compliance requirements, and cost optimization guidelines.

## Policy Overview

The policies evaluate Terraform plan JSON files and provide two types of feedback:

1. **DENY** (Critical): Violations that block deployment
2. **WARN** (Non-blocking): Recommendations and best practices

## DENY Rules (Critical Violations)

These rules must pass for the deployment to succeed. Any violations will cause the CI/CD pipeline to fail.

### 1. Required Tags on Sampling Rules

**Rule**: X-Ray sampling rules must have required tags (Environment and Owner)

**Why**: Tags are essential for cost allocation, resource management, and compliance tracking.

**Violation Examples**:
- Missing `Environment` tag on sampling rule
- Missing `Owner` tag on sampling rule

**How to Fix**:
```hcl
tags = {
  Environment = "dev"
  Owner       = "platform-team"
  # Additional tags as needed
}
```

### 2. Required Tags on X-Ray Groups

**Rule**: X-Ray groups must have required tags (Environment and Owner)

**Why**: Consistent tagging across all X-Ray resources ensures proper organization and billing.

**Violation Examples**:
- Missing `Environment` tag on X-Ray group
- Missing `Owner` tag on X-Ray group

**How to Fix**: Same as sampling rules - ensure all X-Ray groups have Environment and Owner tags.

### 3. Encryption Must Be Enabled

**Rule**: X-Ray encryption configuration must be enabled when using X-Ray resources

**Why**: Trace data may contain sensitive information that should be encrypted at rest.

**Violation Example**:
- Creating sampling rules or groups without an `aws_xray_encryption_config` resource

**How to Fix**:
```hcl
encryption_enabled = true
encryption_type    = "KMS"  # or "NONE" for AWS-managed encryption
```

### 4. Valid Filter Expressions

**Rule**: X-Ray groups must have non-empty filter expressions

**Why**: Empty filter expressions would include all traces, defeating the purpose of grouping.

**Violation Example**:
```hcl
xray_groups = [
  {
    group_name        = "my-group"
    filter_expression = ""  # Invalid: empty string
  }
]
```

**How to Fix**:
```hcl
xray_groups = [
  {
    group_name        = "my-group"
    filter_expression = "http.status >= 500"  # Valid expression
  }
]
```

## WARN Rules (Best Practice Warnings)

These rules provide guidance but do not block deployment. Warnings should be reviewed and addressed when appropriate.

### 1. High Sampling Rates

**Rule**: Sampling rates above 50% trigger a warning

**Why**: High sampling rates significantly increase costs, especially for high-traffic applications.

**When to Ignore**:
- Development environments
- Low-traffic applications
- Temporary troubleshooting

**Recommendation**: Use sampling rates between 0.05 (5%) and 0.10 (10%) for most production workloads.

### 2. 100% Sampling Rate

**Rule**: 100% sampling rate (fixed_rate = 1.0) triggers a warning

**Why**: Tracing every single request can be extremely expensive and is rarely necessary.

**When to Ignore**:
- Very low-traffic services
- Critical debugging scenarios (temporary)

**Recommendation**: Use reservoir_size to ensure a minimum number of traces without sampling everything.

### 3. Non-KMS Encryption

**Rule**: Encryption configurations not using KMS trigger a warning

**Why**: KMS provides enhanced security with customer-managed keys and better audit trails.

**When to Ignore**:
- Development environments
- Cost constraints
- No regulatory requirements for customer-managed keys

**Recommendation**: Use KMS encryption for production environments, especially those handling sensitive data.

## Running Policy Validation

### Check Policy Syntax

```bash
opa check modules/xray/policy/main.rego modules/xray/policy/test.rego
```

### Run Policy Tests

```bash
opa test modules/xray/policy/ -v
```

Expected output:
```
PASS: 3/3
```

### Validate Terraform Plan

1. Generate a Terraform plan:
```bash
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
```

2. Run OPA evaluation:
```bash
opa eval -d opa-policies/service_xray_policies.rego -i tfplan.json \
  --fail "count(data.terraform.aws.xray.deny) > 0"
```

3. View violations (if any):
```bash
opa eval -d opa-policies/service_xray_policies.rego -i tfplan.json \
  "data.terraform.aws.xray.deny"
```

4. View warnings:
```bash
opa eval -d opa-policies/service_xray_policies.rego -i tfplan.json \
  "data.terraform.aws.xray.warn"
```

## Policy Violation Examples and Fixes

### Example 1: Missing Required Tags

**Violation**:
```
CRITICAL: X-Ray sampling rule 'module.xray.aws_xray_sampling_rule.this["my-rule"]' is missing required tag 'Environment'
CRITICAL: X-Ray sampling rule 'module.xray.aws_xray_sampling_rule.this["my-rule"]' is missing required tag 'Owner'
```

**Fix**:
```hcl
module "xray" {
  source = "../../modules/xray"

  tags = {
    Environment = "dev"      # Add this
    Owner       = "platform-team"  # Add this
  }
}
```

### Example 2: Missing Encryption Configuration

**Violation**:
```
CRITICAL: X-Ray encryption configuration must be enabled when using X-Ray resources
```

**Fix**:
```hcl
module "xray" {
  source = "../../modules/xray"

  encryption_enabled = true   # Ensure this is true (default)
  encryption_type    = "KMS"  # Or "NONE"
}
```

### Example 3: High Sampling Rate Warning

**Warning**:
```
WARNING: X-Ray sampling rule 'module.xray.aws_xray_sampling_rule.this["my-rule"]' has a high fixed_rate (0.75). Consider reducing for cost optimization
```

**Fix** (if cost is a concern):
```hcl
sampling_rules = [
  {
    rule_name      = "my-rule"
    fixed_rate     = 0.10  # Reduce from 0.75 to 0.10 (10%)
    reservoir_size = 5     # Still trace at least 5 req/sec
  }
]
```

## Testing Your Configuration

The module includes comprehensive OPA tests:

1. **test_valid_xray_config**: Validates that a properly configured X-Ray setup passes all policies
2. **test_invalid_xray_config**: Ensures that configurations with violations are correctly detected
3. **test_deleted_resources_ignored**: Verifies that deleted resources don't trigger false positives

## Integration with CI/CD

These policies are automatically enforced in the CI/CD pipeline:

1. **Pre-commit Hook**: Validates policies before allowing commits
2. **GitHub Actions**: Runs policy validation on pull requests
3. **Manual Validation**: Can be run locally before committing

## Policy Maintenance

When modifying policies:

1. Update the policy rules in `main.rego`
2. Add corresponding test cases in `test.rego`
3. Run `opa test` to verify all tests pass
4. Update this README to document new rules
5. Update the root README with policy changes

## Troubleshooting

### Policy evaluation fails with "undefined"

- Ensure the Terraform plan JSON contains the expected resource types
- Check that helper functions are correctly defined
- Verify the input JSON structure matches the policy expectations

### Tests pass but manual validation fails

- Ensure you're using the correct policy file path
- Verify the Terraform plan JSON is properly formatted
- Check that the OPA version is compatible (tested with OPA 0.55+)

### False positives on deleted resources

- The policy should ignore resources with `actions: ["delete"]`
- If false positives occur, check the `resource_changes_by_type` helper function

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Rego Language Guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [AWS X-Ray Documentation](https://docs.aws.amazon.com/xray/)
- [Terraform Plan JSON Schema](https://www.terraform.io/docs/internals/json-format.html)

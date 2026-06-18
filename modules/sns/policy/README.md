# AWS SNS OPA Policy Documentation

This directory contains Open Policy Agent (OPA) Rego policies that validate AWS SNS Terraform configurations against security, compliance, and best practice requirements.

## Overview

The policies analyze Terraform plan JSON output to identify security violations and provide warnings for suboptimal configurations. Policy validation runs automatically during:

1. **Pre-commit hooks** - Blocks commits with CRITICAL violations
2. **GitHub Actions CI/CD** - Blocks PR merges with CRITICAL violations
3. **Manual validation** - For development and testing

## Policy Rules

### CRITICAL Rules (Deny)

These rules represent security violations that will fail the pipeline and block commits/deployments.

#### 1. KMS Encryption Required

**Rule:** SNS topics must use KMS encryption for data at rest

**Rationale:** Unencrypted SNS topics expose message data to unauthorized access. KMS encryption ensures data is protected at rest and provides audit trails for key usage.

**Violation Example:**
```hcl
resource "aws_sns_topic" "bad" {
  name = "my-topic"
  # Missing: kms_master_key_id
}
```

**Remediation:**
```hcl
resource "aws_sns_topic" "good" {
  name              = "my-topic"
  kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  # Or use alias:
  # kms_master_key_id = "alias/sns-encryption-key"
}
```

**Error Message:**
```
CRITICAL: SNS topic 'my-topic' must use KMS encryption. Specify kms_master_key_id for encryption at rest.
```

#### 2. Required Tags

**Rule:** SNS topics must have `Environment` and `Owner` tags

**Rationale:** Tags enable cost allocation, resource ownership tracking, automated lifecycle policies, and compliance reporting. Missing tags make resources difficult to manage at scale.

**Violation Example:**
```hcl
resource "aws_sns_topic" "bad" {
  name = "my-topic"
  tags = {
    Project = "myapp"
    # Missing: Environment and Owner tags
  }
}
```

**Remediation:**
```hcl
resource "aws_sns_topic" "good" {
  name = "my-topic"
  tags = {
    Environment = "prod"
    Owner       = "platform-team"
    Project     = "myapp"
  }
}
```

**Error Message:**
```
CRITICAL: Missing required tag 'Environment' on SNS topic 'my-topic'.
CRITICAL: Missing required tag 'Owner' on SNS topic 'my-topic'.
```

#### 3. No Wildcard Principal in Topic Policies

**Rule:** SNS topic access policies must not use wildcard (`*`) principal

**Rationale:** Wildcard principals grant access to any AWS account or user, exposing topics to unauthorized publish/subscribe operations. This violates the principle of least privilege and can lead to data breaches or abuse.

**Violation Example:**
```hcl
resource "aws_sns_topic_policy" "bad" {
  arn = aws_sns_topic.example.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"  # VIOLATION!
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.example.arn
    }]
  })
}
```

**Remediation:**
```hcl
resource "aws_sns_topic_policy" "good" {
  arn = aws_sns_topic.example.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:role/MyAppRole"
      }
      Action   = "sns:Publish"
      Resource = aws_sns_topic.example.arn
    }]
  })
}
```

**Error Message:**
```
CRITICAL: SNS topic policy must not use wildcard principal '*'. Use specific AWS accounts/roles for better security.
```

#### 4. FIFO Topic Naming Convention

**Rule:** FIFO topics must have names ending with `.fifo` suffix

**Rationale:** AWS requires FIFO topics to have names ending with `.fifo`. This is an AWS constraint, not optional. Violating this will cause Terraform apply failures.

**Violation Example:**
```hcl
resource "aws_sns_topic" "bad" {
  name       = "my-queue"  # Missing .fifo suffix
  fifo_topic = true
}
```

**Remediation:**
```hcl
resource "aws_sns_topic" "good" {
  name       = "my-queue.fifo"
  fifo_topic = true
}
```

**Error Message:**
```
CRITICAL: FIFO topic 'my-queue' must have a name ending with '.fifo' suffix.
```

### WARNING Rules

These rules represent best practices and cost optimizations. They generate warnings but do not block deployments.

#### 1. Display Name Recommended

**Rule:** SNS topics should have a `display_name` for better identification

**Rationale:** Display names appear in AWS Console, email notifications, and SMS messages, making topics easier to identify and manage. Without a display name, only the ARN is shown.

**Warning Example:**
```hcl
resource "aws_sns_topic" "example" {
  name = "notifications"
  # Missing: display_name
}
```

**Recommendation:**
```hcl
resource "aws_sns_topic" "example" {
  name         = "notifications"
  display_name = "Application Notifications"
}
```

**Warning Message:**
```
WARNING: Consider setting display_name for SNS topic 'notifications' for better identification in AWS console.
```

#### 2. Delivery Policy Recommended

**Rule:** SNS topics should configure `delivery_policy` for retry control

**Rationale:** Delivery policies control retry behavior, backoff strategies, and timeout settings for message delivery. Without explicit configuration, AWS uses default retry policies that may not suit your reliability requirements.

**Warning Example:**
```hcl
resource "aws_sns_topic" "example" {
  name = "alerts"
  # Missing: delivery_policy
}
```

**Recommendation:**
```hcl
resource "aws_sns_topic" "example" {
  name = "alerts"
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 300
        numRetries         = 10
        backoffFunction    = "exponential"
      }
    }
  })
}
```

**Warning Message:**
```
WARNING: Consider configuring delivery_policy for SNS topic 'alerts' to control message delivery retries and backoff.
```

#### 3. Subscription Confirmation Required

**Rule:** Email and HTTP/HTTPS subscriptions require manual confirmation

**Rationale:** AWS requires explicit confirmation for email, email-json, http, and https subscriptions to prevent spam and unauthorized subscriptions. Subscriptions remain in "PendingConfirmation" state until confirmed.

**Warning Example:**
```hcl
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "ops-team@example.com"
}
```

**What to Expect:**
- AWS sends confirmation email/request to endpoint
- User must click confirmation link
- Subscription only becomes active after confirmation
- Consider using SQS or Lambda for automated workflows

**Warning Message:**
```
WARNING: SNS subscription with protocol 'email' requires manual confirmation after creation. Endpoint: ops-team@example.com
```

## Running Tests

### Check Policy Syntax

Validates Rego code compiles without errors:

```bash
opa check modules/sns/policy/main.rego modules/sns/policy/test.rego
```

**Expected Output:**
```
modules/sns/policy/main.rego
modules/sns/policy/test.rego
```

### Run Unit Tests

Executes all policy tests:

```bash
opa test modules/sns/policy/ -v
```

**Expected Output:**
```
modules/sns/policy/test.rego:
data.terraform.aws.sns.test_valid_configuration_no_violations: PASS (2.5ms)
data.terraform.aws.sns.test_invalid_configuration_with_violations: PASS (3.1ms)
data.terraform.aws.sns.test_delete_action_ignored: PASS (1.8ms)
data.terraform.aws.sns.test_fifo_topic_with_correct_suffix: PASS (2.2ms)
--------------------------------------------------------------------------------
PASS: 4/4
```

### Validate Terraform Plan

Test policies against actual Terraform plan:

```bash
# Generate Terraform plan
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Check for CRITICAL violations (blocks commit/PR)
opa eval -d opa-policies/service_sns_policies.rego \
  -i tfplan.json \
  --fail "count(data.terraform.aws.sns.deny) > 0"

# View all CRITICAL violations
opa eval -d opa-policies/service_sns_policies.rego \
  -i tfplan.json \
  "data.terraform.aws.sns.deny"

# View all WARNINGS
opa eval -d opa-policies/service_sns_policies.rego \
  -i tfplan.json \
  "data.terraform.aws.sns.warn"
```

## Integration

### Pre-commit Hook

The commit hook automatically runs policy validation. On commit:

1. Terraform module is validated
2. OPA policies are syntax-checked and tested
3. Dev implementation is built
4. Terraform plan is generated
5. **OPA policies validate the plan**
6. Commit blocked if CRITICAL violations found

Location: `.husky/commit-msg`

### CI/CD Pipeline

GitHub Actions workflow validates policies on every PR:

- **Job:** "Terraform Implementation Validation"
- **Step:** "OPA Policy Check"
- **Command:** Same as pre-commit hook
- **Result:** PR blocked if violations found

Workflow file: `.github/workflows/pr-validation.yml`

## Troubleshooting

### Common Violations

**Problem:** CRITICAL violations blocking commit

**Solution:** Fix the configuration issues:

1. Read the error message carefully
2. Identify which resource is violating the policy
3. Apply the remediation from this README
4. Commit again

**Example workflow:**
```bash
# Commit fails with violation
$ git commit -m "feat: add sns topic"
❌ CRITICAL: SNS topic 'my-topic' must use KMS encryption

# Fix the issue
$ vim environments/dev/services/sns/service_sns.tfvars
# Add: kms_master_key_id = "alias/dev-sns-key"

# Commit succeeds
$ git commit -m "feat: add sns topic with kms encryption"
✅ No policy violations detected
```

### Debugging Policy Rules

To test a specific rule:

```bash
# Create test plan JSON
cat > test_plan.json <<EOF
{
  "resource_changes": [{
    "address": "aws_sns_topic.test",
    "type": "aws_sns_topic",
    "change": {
      "actions": ["create"],
      "after": {
        "name": "test-topic",
        "kms_master_key_id": null,
        "tags": {}
      }
    }
  }]
}
EOF

# Test against policy
opa eval -d modules/sns/policy/main.rego \
  -i test_plan.json \
  "data.terraform.aws.sns.deny"
```

### Exempting Resources (Not Recommended)

If you absolutely must bypass a policy:

1. **DO NOT** bypass via `--no-verify` in commits
2. **DO** document why the exemption is needed
3. **DO** get security team approval
4. **DO** create a ticket to remediate later

**Note:** CI/CD will still run policies, so exemptions don't work in production.

## Policy Maintenance

### Adding New Rules

1. Add rule to `main.rego`
2. Add test case to `test.rego`
3. Run `opa test` to verify
4. Update this README with rule documentation
5. Update root README with rule summary

### Modifying Existing Rules

1. Update rule in `main.rego`
2. Update or add test cases
3. Verify all tests pass
4. Update documentation
5. Consider backwards compatibility

## References

- [OPA Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [AWS SNS Best Practices](https://docs.aws.amazon.com/sns/latest/dg/sns-best-practices.html)
- [AWS SNS Security](https://docs.aws.amazon.com/sns/latest/dg/sns-security.html)
- [Terraform AWS SNS Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)

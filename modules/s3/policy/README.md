# OPA Policy Validation for AWS S3

This directory contains Open Policy Agent (OPA) Rego policies that validate Terraform plans for AWS S3 bucket configurations. These policies enforce security best practices and compliance requirements before infrastructure changes are deployed.

## Overview

The OPA policies analyze Terraform plan JSON output and identify violations in two categories:

- **CRITICAL (deny)**: Security violations that will fail the pipeline and block deployment
- **WARNING (warn)**: Best practice recommendations that generate warnings but don't block deployment

## CRITICAL Rules (Deny)

These rules enforce essential security requirements. Any violation will cause the policy evaluation to fail and block the deployment.

### 1. S3 Bucket Must Have Server-Side Encryption Enabled

**Rule**: `deny_s3_encryption_not_enabled`

**Description**: Every S3 bucket must have a corresponding `aws_s3_bucket_server_side_encryption_configuration` resource configured. This ensures data at rest is encrypted.

**Violation Message**:
```
S3 bucket 'aws_s3_bucket.example' does not have server-side encryption enabled. Add aws_s3_bucket_server_side_encryption_configuration resource.
```

**How to Fix**:
```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### 2. S3 Bucket Encryption Must Use AES256 or aws:kms

**Rule**: `deny_s3_encryption_sse_s3_or_kms`

**Description**: The encryption algorithm must be either `AES256` (SSE-S3) or `aws:kms` (SSE-KMS). Plain text or other algorithms are not allowed.

**Violation Message**:
```
S3 bucket encryption configuration 'aws_s3_bucket_server_side_encryption_configuration.example' uses invalid algorithm 'plaintext'. Must use 'AES256' (SSE-S3) or 'aws:kms' (SSE-KMS).
```

**How to Fix**:
```hcl
# Use SSE-S3 (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Or use SSE-KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  }
}
```

### 3. S3 Bucket Must Have Versioning Enabled

**Rule**: `deny_s3_versioning_disabled`

**Description**: Every S3 bucket must have versioning enabled with status set to `"Enabled"`. This protects against accidental deletion and provides data recovery capabilities.

**Violation Message**:
```
S3 bucket 'aws_s3_bucket.example' does not have versioning enabled. Set versioning_configuration.status to 'Enabled' in aws_s3_bucket_versioning resource.
```

**How to Fix**:
```hcl
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### 4. S3 Bucket Must Block All Public Access

**Rule**: `deny_s3_public_access_not_blocked`

**Description**: All four public access block settings must be enabled (set to `true`) to prevent accidental public exposure of data. This includes:
- `block_public_acls`
- `block_public_policy`
- `ignore_public_acls`
- `restrict_public_buckets`

**Violation Message**:
```
S3 bucket 'aws_s3_bucket.example' does not block all public access. All four settings (block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets) must be true in aws_s3_bucket_public_access_block resource.
```

**How to Fix**:
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### 5. S3 Bucket Must Have Required Tags

**Rules**: `deny_s3_missing_required_tags` (two rules: one for Environment, one for Owner)

**Description**: Every S3 bucket must have the following required tags:
- `Environment`: Identifies the environment (e.g., dev, staging, production)
- `Owner`: Identifies the team or individual responsible for the bucket

**Violation Messages**:
```
S3 bucket 'aws_s3_bucket.example' is missing required tag 'Environment'. Add Environment tag to the bucket.
S3 bucket 'aws_s3_bucket.example' is missing required tag 'Owner'. Add Owner tag to the bucket.
```

**How to Fix**:
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "my-app"
  }
}
```

## WARNING Rules (Warn)

These rules provide best practice recommendations for cost optimization and operational excellence. Violations generate warnings but do not block deployments.

### 1. S3 Bucket Should Have Lifecycle Rules

**Rule**: `warn_s3_no_lifecycle_policy`

**Description**: S3 buckets should have lifecycle rules configured to automatically transition objects to cheaper storage classes or expire them, reducing storage costs.

**Warning Message**:
```
S3 bucket 'aws_s3_bucket.example' does not have lifecycle rules configured. Consider adding lifecycle rules to transition objects to IA/Glacier for cost optimization.
```

**How to Resolve**:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "archive-old-objects"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

### 2. S3 Bucket Should Have Access Logging Enabled

**Rule**: `warn_s3_no_logging`

**Description**: S3 buckets should have access logging enabled for audit trails, security analysis, and compliance requirements.

**Warning Message**:
```
S3 bucket 'aws_s3_bucket.example' does not have access logging enabled. Consider enabling logging for audit trails and compliance.
```

**How to Resolve**:
```hcl
resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.example.id

  target_bucket = "my-logs-bucket"
  target_prefix = "s3-access-logs/"
}
```

### 3. S3 Bucket Lifecycle Should Use Storage Class Transitions

**Rule**: `warn_s3_no_intelligent_tiering`

**Description**: When lifecycle rules are configured, they should include storage class transitions (e.g., to STANDARD_IA, INTELLIGENT_TIERING, or GLACIER) for cost optimization.

**Warning Message**:
```
S3 bucket lifecycle configuration 'aws_s3_bucket_lifecycle_configuration.example' does not include any storage class transitions. Consider adding transitions to STANDARD_IA, INTELLIGENT_TIERING, or GLACIER for cost optimization.
```

**How to Resolve**:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "cost-optimization"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}
```

## Running Policy Validation

### Validate Policy Syntax

Check that the Rego policy syntax is correct:

```bash
opa check modules/s3/policy/main.rego modules/s3/policy/test.rego
```

### Run Policy Tests

Execute the unit tests to verify policy behavior:

```bash
opa test modules/s3/policy/ -v
```

Expected output:
```
PASS: 5/5
```

### Validate a Terraform Plan Against Policies

1. Generate a Terraform plan:
```bash
cd environments/dev
terraform init
terraform plan -out=tfplan.binary
```

2. Convert the plan to JSON:
```bash
terraform show -json tfplan.binary > tfplan.json
```

3. Evaluate the plan against OPA policies:
```bash
opa eval -d opa-policies/service_s3_policies.rego -i tfplan.json --fail "count(data.terraform.aws.s3.deny) > 0"
```

**Exit Codes**:
- `0`: No CRITICAL violations found (deployment can proceed)
- `1`: CRITICAL violations found (deployment blocked)

4. To see all violations (both CRITICAL and WARNING):
```bash
opa eval -d opa-policies/service_s3_policies.rego -i tfplan.json "data.terraform.aws.s3"
```

## Interpreting Policy Violations

Policy violations are returned as JSON objects with the following structure:

```json
{
  "msg": "Detailed violation message explaining what's wrong and how to fix it",
  "resource": "aws_s3_bucket.example",
  "severity": "CRITICAL"
}
```

### Example Violation Output

```json
{
  "deny": [
    {
      "msg": "S3 bucket 'aws_s3_bucket.data' does not have server-side encryption enabled. Add aws_s3_bucket_server_side_encryption_configuration resource.",
      "resource": "aws_s3_bucket.data",
      "severity": "CRITICAL"
    },
    {
      "msg": "S3 bucket 'aws_s3_bucket.data' is missing required tag 'Environment'. Add Environment tag to the bucket.",
      "resource": "aws_s3_bucket.data",
      "severity": "CRITICAL"
    }
  ],
  "warn": [
    {
      "msg": "S3 bucket 'aws_s3_bucket.data' does not have access logging enabled. Consider enabling logging for audit trails and compliance.",
      "resource": "aws_s3_bucket.data",
      "severity": "WARNING"
    }
  ]
}
```

## Integration with CI/CD

### Pre-commit Hook Integration

The repository includes pre-commit hooks that automatically validate Terraform code and OPA policies before each commit:

```bash
# Hooks run automatically on git commit
git add .
git commit -m "Add S3 bucket configuration"

# Hooks will run:
# 1. terraform fmt -check
# 2. terraform validate
# 3. opa check
# 4. opa test
```

### GitHub Actions Integration

The CI/CD pipeline validates policies in parallel:

1. **Terraform Validation**: Validates module syntax
2. **OPA Policy Validation**: Checks policy syntax and runs tests
3. **Implementation Validation**: Validates dev environment and runs policy checks against Terraform plan

All three jobs must pass for PR approval.

## Policy Development Guidelines

### Adding New Rules

1. Add the rule to `main.rego` following existing patterns
2. Use helper functions (`resource_changes_by_type`, `get_tags`, `array_contains`)
3. Return violation objects with `msg`, `resource`, and `severity` fields
4. Add corresponding test cases in `test.rego`
5. Run `opa check` and `opa test` to validate

### Testing Best Practices

- Test valid configurations (no violations expected)
- Test invalid configurations (multiple violations expected)
- Test edge cases (deleted resources, update operations)
- Test each encryption type (SSE-S3, SSE-KMS)
- Test warnings separately from critical violations

## Compliance and Security Standards

These policies help enforce compliance with:

- **AWS Well-Architected Framework**: Security pillar best practices
- **CIS AWS Foundations Benchmark**: S3 security controls
- **HIPAA**: Encryption at rest and access logging requirements
- **PCI-DSS**: Data protection and audit logging
- **SOC 2**: Access controls and audit trails
- **GDPR**: Data protection and encryption requirements

## Support and Troubleshooting

### Common Issues

**Issue**: Policy validation fails with "undefined" errors
- **Cause**: Terraform plan JSON structure doesn't match expected format
- **Solution**: Check the actual plan JSON structure using `terraform show -json tfplan.binary | jq .`

**Issue**: Tests pass but real plan validation fails
- **Cause**: Mock data in tests doesn't match real Terraform output
- **Solution**: Use actual Terraform plan JSON to debug policy rules

**Issue**: False positives for deleted resources
- **Cause**: Policy checks resources being deleted
- **Solution**: Policies automatically exclude resources with `action = ["delete"]`

## Further Reading

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terraform Plan JSON Schema](https://www.terraform.io/docs/internals/json-format.html)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [AWS Provider v5.x Migration Guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-5-upgrade)

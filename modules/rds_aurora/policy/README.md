# OPA Policies for AWS RDS Aurora Terraform Module

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS RDS Aurora Terraform configurations against security and compliance requirements.

## Overview

These policies validate Terraform plans before infrastructure changes are applied, ensuring that Aurora database clusters meet security standards, compliance requirements, and operational best practices.

## Policy Structure

- **`main.rego`**: Production policy rules (CRITICAL deny rules and WARNING rules)
- **`test.rego`**: Comprehensive test suite for policy validation

## Policy Rules

### CRITICAL Deny Rules

These rules will **block** Terraform operations if violated. All CRITICAL rules must pass before infrastructure changes can be applied.

#### 1. Encryption at Rest Required

**Rule**: RDS Aurora clusters must have encryption at rest enabled

**Rationale**: Encryption at rest protects sensitive data from unauthorized access if storage media is compromised. Regulatory frameworks (PCI DSS, HIPAA, GDPR) often mandate encryption for databases containing sensitive information.

**Violation Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier  = "my-cluster"
  storage_encrypted   = false  # ❌ VIOLATION
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier  = "my-cluster"
  storage_encrypted   = true   # ✅ COMPLIANT
  kms_key_id          = aws_kms_key.aurora.arn  # Optional: use custom KMS key
  # ... other config
}
```

**Remediation**: Set `storage_encrypted = true` and optionally provide a `kms_key_id` for custom encryption keys.

---

#### 2. Deletion Protection Required

**Rule**: RDS Aurora clusters must have deletion protection enabled

**Rationale**: Deletion protection prevents accidental cluster deletion, which would result in permanent data loss. Production databases should always have this protection enabled.

**Violation Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier  = "my-cluster"
  deletion_protection = false  # ❌ VIOLATION
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier  = "my-cluster"
  deletion_protection = true   # ✅ COMPLIANT
  # ... other config
}
```

**Remediation**: Set `deletion_protection = true` for all production clusters.

---

#### 3. Backup Retention Period Minimum

**Rule**: Backup retention period must be at least 7 days

**Rationale**: Adequate backup retention is critical for disaster recovery and compliance. 7 days provides a reasonable window to recover from data corruption, accidental deletion, or other incidents.

**Violation Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier      = "my-cluster"
  backup_retention_period = 1   # ❌ VIOLATION
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier      = "my-cluster"
  backup_retention_period = 7   # ✅ COMPLIANT (minimum)
  # ... other config
}
```

**Remediation**: Set `backup_retention_period` to at least 7 days (14-30 days recommended for production).

---

#### 4. IAM Database Authentication Required

**Rule**: IAM database authentication should be enabled

**Rationale**: IAM authentication provides centralized identity management, eliminates the need to store database credentials, and enables audit logging of database access through CloudTrail.

**Violation Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier                  = "my-cluster"
  iam_database_authentication_enabled = false  # ❌ VIOLATION
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier                  = "my-cluster"
  iam_database_authentication_enabled = true   # ✅ COMPLIANT
  # ... other config
}
```

**Remediation**: Set `iam_database_authentication_enabled = true` and configure IAM roles for database access.

---

#### 5. Required Tags Present

**Rule**: Clusters must have `Environment` and `Owner` tags

**Rationale**: Required tags enable resource organization, cost allocation, access control, and compliance tracking. `Environment` identifies deployment stage (dev/staging/prod), and `Owner` identifies the responsible team.

**Violation Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier = "my-cluster"
  tags = {
    Application = "MyApp"  # ❌ VIOLATION: Missing Environment and Owner
  }
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier = "my-cluster"
  tags = {
    Environment = "production"    # ✅ COMPLIANT
    Owner       = "platform-team" # ✅ COMPLIANT
    Application = "MyApp"
  }
  # ... other config
}
```

**Remediation**: Add `Environment` and `Owner` tags to all Aurora clusters.

---

#### 6. Instances Must Not Be Publicly Accessible

**Rule**: RDS Aurora instances must not be publicly accessible

**Rationale**: Public accessibility exposes databases to the internet, significantly increasing attack surface. Databases should only be accessible from within the VPC through private subnets.

**Violation Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier          = "my-instance"
  publicly_accessible = true  # ❌ VIOLATION
  # ... other config
}
```

**Compliant Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier          = "my-instance"
  publicly_accessible = false  # ✅ COMPLIANT
  # ... other config
}
```

**Remediation**: Set `publicly_accessible = false` and ensure instances are in private subnets.

---

### WARNING Rules

These rules provide **non-blocking warnings** for best practices. They don't prevent deployment but should be addressed for production environments.

#### 1. Multi-AZ Deployment Recommended

**Rule**: Clusters should have at least 2 instances for high availability

**Rationale**: Multi-AZ deployment provides automatic failover and increased read capacity. Single-instance clusters have no failover capability.

**Warning Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  count      = 1  # ⚠️ WARNING: Single instance, no HA
  identifier = "my-instance-${count.index}"
  # ... other config
}
```

**Recommended**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  count      = 2  # ✅ Multiple instances for HA
  identifier = "my-instance-${count.index}"
  # ... other config
}
```

---

#### 2. Performance Insights Recommended

**Rule**: Performance Insights should be enabled for monitoring

**Rationale**: Performance Insights provides detailed database performance data, helping identify performance bottlenecks and optimize query performance.

**Warning Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier                   = "my-instance"
  performance_insights_enabled = false  # ⚠️ WARNING
  # ... other config
}
```

**Recommended**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier                   = "my-instance"
  performance_insights_enabled = true   # ✅ Recommended
  # ... other config
}
```

---

#### 3. Enhanced Monitoring Recommended

**Rule**: Enhanced monitoring should be enabled

**Rationale**: Enhanced Monitoring provides real-time metrics for the operating system, helping diagnose performance issues and capacity planning.

**Warning Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier          = "my-instance"
  monitoring_interval = 0  # ⚠️ WARNING: Monitoring disabled
  # ... other config
}
```

**Recommended**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier          = "my-instance"
  monitoring_interval = 60  # ✅ Recommended (1 minute intervals)
  # ... other config
}
```

---

#### 4. CloudWatch Logs Export Recommended

**Rule**: Database logs should be exported to CloudWatch

**Rationale**: Centralized logging enables security auditing, troubleshooting, and compliance monitoring.

**Warning Example**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier              = "my-cluster"
  enabled_cloudwatch_logs_exports = []  # ⚠️ WARNING: No log export
  # ... other config
}
```

**Recommended**:
```hcl
resource "aws_rds_cluster" "example" {
  cluster_identifier              = "my-cluster"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]  # ✅ Recommended (MySQL)
  # For PostgreSQL: ["postgresql"]
  # ... other config
}
```

---

#### 5. Non-Burstable Instance Classes for Production

**Rule**: Consider using non-burstable instance classes for production workloads

**Rationale**: Burstable instances (db.t3.*, db.t4g.*) have limited CPU credit pools and may throttle under sustained load. Production workloads should use db.r* (memory-optimized) or db.m* (general-purpose) instances.

**Warning Example**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier     = "my-instance"
  instance_class = "db.t3.medium"  # ⚠️ WARNING: Burstable instance
  # ... other config
}
```

**Recommended**:
```hcl
resource "aws_rds_cluster_instance" "example" {
  identifier     = "my-instance"
  instance_class = "db.r5.large"  # ✅ Recommended for production
  # ... other config
}
```

---

## Running Policy Validation

### Check Policy Syntax

```bash
opa check modules/rds_aurora/policy/main.rego modules/rds_aurora/policy/test.rego
```

### Run Policy Tests

```bash
opa test modules/rds_aurora/policy/ -v
```

Expected output:
```
modules/rds_aurora/policy/test.rego:
data.terraform.aws.rds_aurora.test_valid_configuration: PASS (2.1ms)
data.terraform.aws.rds_aurora.test_missing_encryption: PASS (1.8ms)
data.terraform.aws.rds_aurora.test_missing_tags: PASS (1.9ms)
data.terraform.aws.rds_aurora.test_publicly_accessible: PASS (1.7ms)
data.terraform.aws.rds_aurora.test_low_backup_retention: PASS (1.6ms)
data.terraform.aws.rds_aurora.test_delete_action_ignored: PASS (1.5ms)
data.terraform.aws.rds_aurora.test_single_instance_warning: PASS (1.8ms)
data.terraform.aws.rds_aurora.test_no_deletion_protection: PASS (1.7ms)
data.terraform.aws.rds_aurora.test_no_iam_authentication: PASS (1.6ms)
--------------------------------------------------------------------------------
PASS: 9/9
```

### Validate Terraform Plan

```bash
cd environments/dev/
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Check for CRITICAL violations (exits with code 1 if violations found)
opa eval -d opa-policies/service_rds_aurora_policies.rego \
         -i tfplan.json \
         --fail "count(data.terraform.aws.rds_aurora.deny) > 0"

# Display CRITICAL violations (for debugging)
opa eval -d opa-policies/service_rds_aurora_policies.rego \
         -i tfplan.json \
         "data.terraform.aws.rds_aurora.deny"

# Display WARNING violations (informational)
opa eval -d opa-policies/service_rds_aurora_policies.rego \
         -i tfplan.json \
         "data.terraform.aws.rds_aurora.warn"
```

## Policy Evaluation Workflow

1. **Terraform Plan Generation**: `terraform plan -out=tfplan.binary`
2. **Convert to JSON**: `terraform show -json tfplan.binary > tfplan.json`
3. **OPA Evaluation**: OPA reads the JSON plan as `input`
4. **Rule Evaluation**: Each `deny` and `warn` rule is evaluated against the resources
5. **Result Collection**: Violations are collected in the `deny` and `warn` sets
6. **Exit Code**: If `count(deny) > 0`, OPA returns exit code 1 (blocking)

## Troubleshooting

### Policy Test Failures

```bash
# Run tests with verbose output
opa test modules/rds_aurora/policy/ -v

# Debug specific test
opa eval -d modules/rds_aurora/policy/main.rego \
         -d modules/rds_aurora/policy/test.rego \
         "data.terraform.aws.rds_aurora.test_missing_encryption"
```

### Policy Violations

**Problem**: Commit blocked due to policy violations

**Solution**: Review the violation message and update Terraform configuration:

```bash
# Example violation message:
# RDS Aurora cluster 'module.rds_aurora.aws_rds_cluster.this' must have
# encryption at rest enabled (storage_encrypted = true)

# Fix in your .tfvars or module configuration:
storage_encrypted = true
```

### Common Issues

1. **Missing Tags**: Add `Environment` and `Owner` tags to all clusters
2. **Public Access**: Set `publicly_accessible = false` for all instances
3. **Weak Backups**: Set `backup_retention_period >= 7`
4. **No Encryption**: Set `storage_encrypted = true`

## Integration

These policies integrate with:

- **Pre-commit Hooks**: Automatically validate before commits
- **GitHub Actions**: Validate on pull requests (`.github/workflows/pr-validation.yml`)
- **CI/CD Pipelines**: Block deployments if CRITICAL violations exist

## Authors

Generated with Claude Code

## References

- [OPA Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [AWS RDS Aurora Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_BestPractices.html)
- [AWS RDS Security Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html)

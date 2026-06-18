# AWS Secrets Manager OPA Policies

OPA Rego policies that validate Terraform plans for AWS Secrets Manager against security best practices.

## Policy Rules

### DENY Rules (Critical - Will Fail Pipeline)

**1. Secrets Must Use Customer-Managed KMS Keys**
- Secrets must specify `kms_key_id` (customer-managed KMS key)
- AWS managed keys (default) are not allowed for production

**2. Secrets Must Have Required Tags**
- Required tags: `Environment`, `Owner`, `Application`
- Used for governance and cost tracking

**3. Secret Policies Must Not Use Wildcard Principals**
- Resource policies must not use `Principal: "*"`
- Access should be granted to specific IAM principals only

**4. Secrets Must Have Recovery Window > 0 Days**
- `recovery_window_in_days` must be > 0
- Immediate deletion (0 days) is not allowed for safety

### WARN Rules (Best Practices - Informational)

**1. Secrets Should Have Descriptions**
- Include `description` for documentation

**2. Consider Enabling Automatic Rotation**
- Critical secrets should have rotation configured

**3. Recovery Window Should Be >= 7 Days**
- Recommended minimum is 7 days for safety

## Running Policy Checks

```bash
# Validate syntax
opa check modules/secretsmanager/policy/main.rego modules/secretsmanager/policy/test.rego

# Run tests
opa test modules/secretsmanager/policy/ -v

# Check Terraform plan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
opa eval -d opa-policies/service_secretsmanager_policies.rego \
  -i tfplan.json \
  --fail "count(data.terraform.aws.secretsmanager.deny) > 0"
```

## Example Violations

```hcl
# DENY: Missing KMS key
resource "aws_secretsmanager_secret" "bad" {
  name = "my-secret"
  # kms_key_id missing
}

# DENY: Missing required tags
resource "aws_secretsmanager_secret" "bad" {
  name = "my-secret"
  tags = {
    Environment = "dev"  # Missing Owner and Application
  }
}

# DENY: Immediate deletion
resource "aws_secretsmanager_secret" "bad" {
  name                    = "my-secret"
  recovery_window_in_days = 0  # Not allowed
}
```

## Example Valid Configuration

```hcl
resource "aws_secretsmanager_secret" "good" {
  name        = "my-secret"
  description = "Database credentials"
  kms_key_id  = aws_kms_key.secrets.arn

  recovery_window_in_days = 30

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Application = "database"
  }
}
```

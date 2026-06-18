# AWS Certificate Manager OPA Policy Documentation

This directory contains Open Policy Agent (OPA) Rego policies that validate Terraform plans for AWS Certificate Manager (ACM) resources against security best practices and compliance requirements.

## Overview

These policies enforce security standards and compliance requirements for SSL/TLS certificates managed through AWS Certificate Manager. The policies run during CI/CD pipelines and pre-commit hooks to catch misconfigurations before deployment.

## Policy Types

### CRITICAL (DENY) Rules

These violations will fail CI/CD pipelines and block deployments. They represent security risks or compliance violations that must be addressed.

### WARNING Rules

These are best practice recommendations that generate warnings but do not block deployments. Teams should review and address warnings when possible.

## CRITICAL Policy Rules

### 1. Required Tags

**Rule:** All certificates must have Environment, Owner, and Project tags

**Rationale:**
- Tags enable cost allocation and tracking across teams
- Required for compliance and audit trails
- Essential for resource lifecycle management

**Example Violation:**
```hcl
resource "aws_acm_certificate" "bad" {
  domain_name = "example.com"

  tags = {
    Environment = "dev"
    # Missing Owner and Project tags
  }
}
```

**Remediation:**
```hcl
resource "aws_acm_certificate" "good" {
  domain_name = "example.com"

  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    Project     = "web-application"
  }
}
```

### 2. DNS Validation Required

**Rule:** Certificates must use DNS validation method, not EMAIL

**Rationale:**
- EMAIL validation is deprecated by AWS
- DNS validation enables automated certificate renewal
- DNS validation is more secure and doesn't rely on email delivery
- EMAIL validation requires manual intervention for renewals

**Example Violation:**
```hcl
resource "aws_acm_certificate" "bad" {
  domain_name       = "example.com"
  validation_method = "EMAIL"  # Deprecated
}
```

**Remediation:**
```hcl
resource "aws_acm_certificate" "good" {
  domain_name       = "example.com"
  validation_method = "DNS"  # Recommended
}
```

### 3. Certificate Transparency Logging Enabled

**Rule:** Certificate transparency logging must be enabled

**Rationale:**
- Required for compliance and auditability
- Enables public monitoring of certificate issuance
- Helps detect unauthorized certificate creation
- Industry best practice for public certificates

**Example Violation:**
```hcl
resource "aws_acm_certificate" "bad" {
  domain_name = "example.com"

  options {
    certificate_transparency_logging_preference = "DISABLED"
  }
}
```

**Remediation:**
```hcl
resource "aws_acm_certificate" "good" {
  domain_name = "example.com"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
}
```

### 4. Secure Key Algorithm

**Rule:** Certificates must use secure key algorithms (RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1)

**Rationale:**
- Weak algorithms like RSA_1024 are cryptographically vulnerable
- Industry standards require minimum RSA_2048 or EC equivalent
- Future-proof certificate security
- Compliance requirements mandate strong cryptographic algorithms

**Allowed Algorithms:**
- RSA_2048 (default, widely supported)
- RSA_4096 (stronger RSA key)
- EC_prime256v1 (NIST P-256, efficient and secure)
- EC_secp384r1 (NIST P-384, higher security)

**Example Violation:**
```hcl
resource "aws_acm_certificate" "bad" {
  domain_name   = "example.com"
  key_algorithm = "RSA_1024"  # Too weak
}
```

**Remediation:**
```hcl
resource "aws_acm_certificate" "good" {
  domain_name   = "example.com"
  key_algorithm = "RSA_2048"  # Secure default
}
```

### 5. Valid Domain Name

**Rule:** Certificate domain name must not be empty

**Rationale:**
- Empty domain names cause certificate creation failures
- Prevents deployment errors
- Ensures proper certificate configuration

**Example Violation:**
```hcl
resource "aws_acm_certificate" "bad" {
  domain_name = ""  # Empty
}
```

**Remediation:**
```hcl
resource "aws_acm_certificate" "good" {
  domain_name = "example.com"
}
```

## WARNING Policy Rules

### 1. Wildcard Certificate Usage

**Warning:** Wildcard certificates should be used carefully

**Rationale:**
- Wildcard certificates (*.example.com) cover all subdomains
- If compromised, all subdomains are at risk
- Consider using specific domain names with SANs for better security granularity
- Wildcards are acceptable for trusted internal services

**Example:**
```hcl
resource "aws_acm_certificate" "wildcard" {
  domain_name = "*.example.com"  # Triggers warning

  # Alternative: Use specific domains with SANs
  # domain_name = "app.example.com"
  # subject_alternative_names = ["api.example.com", "www.example.com"]
}
```

### 2. No Subject Alternative Names

**Warning:** Consider using SANs if multiple domains need coverage

**Rationale:**
- Single certificates with multiple SANs are easier to manage than multiple certificates
- Cost optimization - one certificate covers multiple domains
- Simplified certificate rotation and renewal

**Example:**
```hcl
# Single certificate covering multiple domains
resource "aws_acm_certificate" "multi_domain" {
  domain_name = "example.com"
  subject_alternative_names = [
    "www.example.com",
    "api.example.com",
    "app.example.com"
  ]
}
```

### 3. Large Number of SANs

**Warning:** Certificates with >50 SANs should be split

**Rationale:**
- Too many SANs make certificates difficult to manage
- Certificate rotation affects many services simultaneously
- May indicate architectural issues
- Some systems have limits on certificate size

**Example:**
```hcl
# Consider splitting into multiple certificates
resource "aws_acm_certificate" "too_many_sans" {
  domain_name = "example.com"
  subject_alternative_names = [
    # 51+ domains triggers warning
  ]
}
```

## Testing Policies

Run policy tests to verify all rules work correctly:

```bash
# Run all tests
opa test modules/certificatemanager/policy/ -v

# Expected output: 10/10 tests passed
```

## Validating Terraform Plans

Validate your Terraform plan against these policies:

```bash
# Generate Terraform plan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json

# Evaluate policies
opa eval -d modules/certificatemanager/policy/main.rego \
         -i tfplan.json \
         --fail "count(data.terraform.aws.certificatemanager.deny) > 0"

# Check for warnings (informational)
opa eval -d modules/certificatemanager/policy/main.rego \
         -i tfplan.json \
         --format pretty \
         "data.terraform.aws.certificatemanager.warn"
```

## CI/CD Integration

These policies are automatically enforced in:

1. **Pre-commit Hooks**: Local validation before commit
2. **GitHub Actions PR Validation**: Automated checks on pull requests
3. **Release Pipeline**: Final validation before deployment

## Policy Maintenance

### Adding New Rules

1. Add the rule to `main.rego` in the appropriate section (deny or warn)
2. Create test cases in `test.rego` for valid and invalid configurations
3. Run tests to verify: `opa test modules/certificatemanager/policy/ -v`
4. Document the rule in this README with rationale and remediation

### Modifying Existing Rules

1. Update the rule in `main.rego`
2. Update or add test cases in `test.rego`
3. Run tests to ensure no regressions
4. Update this README if the rule behavior changes

## Compliance Frameworks

These policies help meet requirements from:

- **PCI DSS**: Strong cryptography, certificate management
- **SOC 2**: Security monitoring, access controls, audit trails
- **HIPAA**: Encryption standards, certificate lifecycle management
- **ISO 27001**: Cryptographic controls, certificate transparency

## Additional Resources

- [AWS Certificate Manager Documentation](https://docs.aws.amazon.com/acm/)
- [OPA Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Certificate Transparency](https://certificate.transparency.dev/)
- [NIST Cryptographic Standards](https://csrc.nist.gov/projects/cryptographic-standards-and-guidelines)

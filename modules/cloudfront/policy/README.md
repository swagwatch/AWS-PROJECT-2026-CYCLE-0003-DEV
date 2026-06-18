# CloudFront OPA Security Policies

Open Policy Agent (OPA) policies for validating AWS CloudFront Terraform configurations against security best practices.

## Overview

These policies automatically validate Terraform plans before deployment to ensure CloudFront distributions meet security, compliance, and operational standards.

## Policy Rules

### CRITICAL Rules (deny - blocks deployment)

| Rule | Description | Rationale |
|------|-------------|-----------|
| **HTTPS Enforcement** | Viewer protocol must be `https-only` or `redirect-to-https` | Prevents unencrypted HTTP traffic, protecting data in transit |
| **TLS Version** | Minimum TLS version must be `TLSv1.2_2021` or `TLSv1.3_2021` | Deprecated TLS versions (SSLv3, TLSv1.0, TLSv1.1) have known vulnerabilities |
| **Required Tags** | `Environment` and `Owner` tags must be present | Ensures accountability and resource organization |
| **Secure Origins** | Custom origins cannot use `http-only` protocol | Prevents man-in-the-middle attacks between CloudFront and origin |
| **Default Root Object** | Must be set (non-empty) | Prevents directory listing exposure and information disclosure |
| **Production Logging** | Access logging required for prod/production environments | Enables security auditing and incident response |
| **Production WAF** | WAF Web ACL required for prod/production environments | Protects against common web exploits (OWASP Top 10) |

### WARNING Rules (non-blocking)

| Rule | Description | Rationale |
|------|-------------|-----------|
| **Price Class** | Warn if using `PriceClass_All` | Most expensive option; evaluate if global edge locations are needed |
| **Compression** | Warn if compression is disabled | Reduces bandwidth costs and improves performance |
| **HTTP Version** | Warn if using HTTP/1.1 | HTTP/2 and HTTP/3 provide better performance |
| **Origin Timeout** | Warn if origin read timeout > 60 seconds | High timeouts negatively impact user experience |
| **Cache TTL** | Warn if max TTL > 1 year | Excessively high TTLs reduce cache freshness |
| **Non-Production Logging** | Warn if logging disabled in dev/staging | Useful for troubleshooting and analytics |

## Usage

### Running Policy Validation Locally

```bash
# Validate policy syntax
opa check modules/cloudfront/policy/main.rego modules/cloudfront/policy/test.rego

# Run policy tests
opa test modules/cloudfront/policy/ -v

# Validate a Terraform plan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
opa eval -d modules/cloudfront/policy/main.rego -i tfplan.json "data.terraform.aws.cloudfront.deny"

# Fail if CRITICAL violations exist
opa eval -d modules/cloudfront/policy/main.rego -i tfplan.json --fail "count(data.terraform.aws.cloudfront.deny) > 0"

# Check WARNING rules
opa eval -d modules/cloudfront/policy/main.rego -i tfplan.json "data.terraform.aws.cloudfront.warn"
```

### CI/CD Integration

These policies are automatically run by:
- **Pre-commit hooks**: Validates changes before commit
- **GitHub Actions**: Validates PRs before merge (see `.github/workflows/pr-validation.yml`)

## Writing Tests

Tests are located in `test.rego`. Each test validates specific policy behavior:

```rego
# Example test structure
test_my_policy if {
    result := deny with input as {
        "resource_changes": [{
            "type": "aws_cloudfront_distribution",
            "change": {
                "actions": ["create"],
                "after": {
                    # Test configuration here
                }
            }
        }]
    }

    count(result) == 0  # Assert no violations
}
```

Test categories:
- **Valid configuration**: No violations expected
- **Invalid configuration**: Multiple violations expected
- **Edge cases**: Deleted resources, null values, empty arrays

## Adding New Policy Rules

1. **Add the rule** to `main.rego`:
   ```rego
   deny contains msg if {
       resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
       after := resource.change.after

       # Your validation logic here

       msg := {
           "msg": sprintf("Violation description for '%s'", [resource.address]),
           "resource": resource.address,
       }
   }
   ```

2. **Add tests** in `test.rego`:
   ```rego
   test_my_new_rule if {
       result := deny with input as { /* test data */ }
       count(result) > 0
       some violation in result
       contains(violation.msg, "expected violation text")
   }
   ```

3. **Validate and test**:
   ```bash
   opa check modules/cloudfront/policy/*.rego
   opa test modules/cloudfront/policy/ -v
   ```

4. **Document the rule** in this README

## Troubleshooting

### Policy syntax errors
```bash
# Check for syntax errors
opa check modules/cloudfront/policy/main.rego
```

### Test failures
```bash
# Run tests with verbose output
opa test modules/cloudfront/policy/ -v

# Run specific test
opa test modules/cloudfront/policy/ -v -r test_valid_configuration_no_violations
```

### False positives
- Review the Terraform plan JSON structure
- Verify the policy logic matches actual plan format
- Check for null values or missing fields in the plan

### Understanding policy logic
- Use `opa eval` to inspect intermediate values
- Add debug prints in policies (results visible in test output)
- Review helper functions: `resource_changes_by_type`, `get_tags`, `array_contains`

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terraform JSON Plan Format](https://www.terraform.io/docs/internals/json-format.html)
- [AWS CloudFront Security Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security-best-practices.html)

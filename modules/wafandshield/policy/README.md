# WAF and Shield OPA Policy Validation

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS WAF and Shield Terraform configurations before deployment.

## Overview

The policies automatically validate Terraform plans to ensure security best practices and compliance requirements are met. Policies are categorized into two levels:

- **CRITICAL (deny)**: Violations that will block deployment
- **WARNING (warn)**: Best practice recommendations that don't block deployment

## Policy Rules

### CRITICAL Deny Rules

These rules will fail the pipeline if violated:

#### 1. Missing Environment Tag
**Rule**: WAF Web ACL must have 'Environment' tag
**Reason**: Required for resource tracking and cost allocation
**Example Violation**: Creating a WAF Web ACL without an Environment tag
**Fix**: Add `Environment` tag to all WAF resources

```hcl
tags = {
  Environment = "dev"
  Owner       = "platform-team"
}
```

#### 2. Missing Owner Tag
**Rule**: WAF Web ACL must have 'Owner' tag
**Reason**: Required for accountability and resource management
**Example Violation**: Creating a WAF Web ACL without an Owner tag
**Fix**: Add `Owner` tag to all WAF resources

```hcl
tags = {
  Environment = "dev"
  Owner       = "platform-team"
}
```

#### 3. CloudWatch Metrics Disabled
**Rule**: CloudWatch metrics must be enabled for security monitoring
**Reason**: Required for monitoring WAF performance and detecting attacks
**Example Violation**: Setting `cloudwatch_metrics_enabled = false`
**Fix**: Ensure CloudWatch metrics are enabled

```hcl
visibility_config = {
  cloudwatch_metrics_enabled = true
  metric_name                = "waf-metrics"
  sampled_requests_enabled   = true
}
```

#### 4. Sampled Requests Disabled
**Rule**: Sampled requests must be enabled for security forensics
**Reason**: Required for security incident investigation and analysis
**Example Violation**: Setting `sampled_requests_enabled = false`
**Fix**: Ensure sampled requests are enabled

```hcl
visibility_config = {
  cloudwatch_metrics_enabled = true
  metric_name                = "waf-metrics"
  sampled_requests_enabled   = true
}
```

#### 5. Wildcard Characters in Name
**Rule**: WAF Web ACL name cannot contain wildcard characters (*)
**Reason**: Prevents configuration errors and security risks
**Example Violation**: `name = "waf-*-acl"`
**Fix**: Use explicit names without wildcards

```hcl
name = "waf-production-acl"
```

### WARNING Rules

These rules generate warnings but don't block deployment:

#### 1. No Rate Limiting Rules
**Rule**: Consider adding rate limiting rules to protect against DDoS attacks
**Reason**: Rate limiting helps prevent application-layer DDoS attacks
**Recommendation**: Add a rate-based rule

```hcl
rules = [
  {
    name     = "RateLimitRule"
    priority = 1
    action   = "count"
    statement = {
      rate_based_statement = {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
  }
]
```

#### 2. No AWS Managed Rules
**Rule**: Consider using AWS Managed Rule Groups for common vulnerability protection
**Reason**: AWS Managed Rules provide protection against OWASP Top 10 and common CVEs
**Recommendation**: Add AWS Managed Rules

```hcl
rules = [
  {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1
    action   = "none"
    statement = {
      managed_rule_group_statement = {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
  }
]
```

#### 3. No Geo-Blocking Rules
**Rule**: Consider adding geo-blocking rules to restrict access by geographic location
**Reason**: Geo-blocking can reduce attack surface by blocking traffic from unwanted regions
**Recommendation**: Add geo-match rules if appropriate

```hcl
rules = [
  {
    name     = "GeoBlockRule"
    priority = 2
    action   = "count"
    statement = {
      geo_match_statement = {
        country_codes = ["CN", "RU"]
      }
    }
  }
]
```

#### 4. Shield Advanced in Non-Production
**Rule**: AWS Shield Advanced is expensive and typically only justified for production environments
**Reason**: Shield Advanced costs $3000/month minimum and should only be used where justified
**Recommendation**: Only enable Shield Advanced for production resources

## Running Policy Validation

### Syntax Check
Verify policy syntax is correct:

```bash
opa check modules/wafandshield/policy/main.rego
```

### Run Tests
Execute all policy unit tests:

```bash
opa test modules/wafandshield/policy/ -v
```

Expected output:
```
PASS: 4/4
```

### Validate Terraform Plan
Validate a Terraform plan against the policies:

```bash
# Generate plan
terraform plan -out=tfplan.binary

# Convert to JSON
terraform show -json tfplan.binary > tfplan.json

# Run OPA validation
opa eval -d modules/wafandshield/policy/main.rego -i tfplan.json --fail "count(data.terraform.aws.wafandshield.deny) > 0"
```

If there are CRITICAL violations, the command will exit with code 1 and display the violations.

### Check for Warnings
To see warning-level violations (non-blocking):

```bash
opa eval -d modules/wafandshield/policy/main.rego -i tfplan.json "data.terraform.aws.wafandshield.warn"
```

## Common Violations and Fixes

### Violation: Missing Required Tags
**Error Message**: "WAF Web ACL must have 'Environment' tag" or "WAF Web ACL must have 'Owner' tag"

**Fix**: Add required tags to your module configuration:

```hcl
module "waf" {
  source = "../../modules/wafandshield"

  name        = "my-waf"
  scope       = "REGIONAL"
  environment = "dev"      # Required
  owner       = "team-name" # Required

  tags = {
    Project = "my-app"
  }
}
```

### Violation: Logging Disabled
**Error Message**: "WAF Web ACL must have CloudWatch metrics enabled" or "sampled requests enabled"

**Fix**: Ensure visibility config is properly set:

```hcl
visibility_config = {
  cloudwatch_metrics_enabled = true
  metric_name                = "my-waf-metrics"
  sampled_requests_enabled   = true
}
```

### Violation: Wildcard in Name
**Error Message**: "WAF Web ACL name cannot contain wildcard characters"

**Fix**: Remove wildcards from the name:

```hcl
# Bad
name = "waf-*-acl"

# Good
name = "waf-production-acl"
```

## Integration with CI/CD

These policies are automatically executed by:

1. **Pre-commit hooks**: Run before commits are created
2. **GitHub Actions CI**: Run on all pull requests
3. **Deployment pipelines**: Run before infrastructure changes are applied

Any CRITICAL violations will block the deployment, while WARNINGs are logged but don't block.

## Policy Development

### Adding New Rules

To add new policy rules:

1. Edit `main.rego` and add your rule under the appropriate section (deny or warn)
2. Add test cases to `test.rego`
3. Run tests to verify: `opa test modules/wafandshield/policy/ -v`
4. Update this README with documentation for the new rule

### Testing Policies

All policies should have corresponding test cases:

- Valid configurations (should pass)
- Invalid configurations (should fail)
- Delete actions (should be ignored)
- Edge cases

See `test.rego` for examples.

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terraform JSON Plan Format](https://www.terraform.io/docs/internals/json-format.html)
- [AWS WAF Best Practices](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)

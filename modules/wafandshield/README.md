# AWS WAF and Shield Terraform Module

This Terraform module provides a standardized way to deploy and manage AWS WAF (Web Application Firewall) and Shield resources with built-in OPA policy validation.

## Overview

The module creates AWS WAF v2 Web ACLs with customizable rules and optionally enables AWS Shield Advanced protection. All configurations are automatically validated against security and compliance policies using Open Policy Agent (OPA) before deployment.

## Features

- **AWS WAF v2 Web ACL**: Create and manage Web Application Firewall rules
- **Flexible Rule Configuration**: Support for managed rules, rate-based rules, and geo-blocking
- **AWS Shield Protection**: Optional AWS Shield Advanced DDoS protection
- **Automated Validation**: Built-in OPA policies enforce security best practices
- **Comprehensive Tagging**: Automatic tagging with environment, owner, and custom tags
- **CloudWatch Integration**: Built-in metrics and request sampling for monitoring
- **Scope Support**: Deploy to REGIONAL (ALB, API Gateway) or CLOUDFRONT resources

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## Usage

### Basic WAF Web ACL

```hcl
module "waf" {
  source = "../../modules/wafandshield"

  name        = "my-web-acl"
  scope       = "REGIONAL"
  description = "WAF for ALB protection"

  environment = "dev"
  owner       = "platform-team"

  tags = {
    Project = "my-app"
  }
}
```

### WAF with AWS Managed Rules

```hcl
module "waf_with_rules" {
  source = "../../modules/wafandshield"

  name  = "my-web-acl"
  scope = "REGIONAL"

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
        rate_based_statement   = null
        geo_match_statement    = null
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
      }
    }
  ]

  environment = "prod"
  owner       = "security-team"
}
```

### WAF with Rate Limiting and Geo-Blocking

```hcl
module "waf_advanced" {
  source = "../../modules/wafandshield"

  name  = "advanced-web-acl"
  scope = "REGIONAL"

  rules = [
    {
      name     = "RateLimitRule"
      priority = 1
      action   = "count"
      statement = {
        managed_rule_group_statement = null
        rate_based_statement = {
          limit              = 2000
          aggregate_key_type = "IP"
        }
        geo_match_statement = null
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "RateLimitRule"
        sampled_requests_enabled   = true
      }
    },
    {
      name     = "GeoBlockRule"
      priority = 2
      action   = "count"
      statement = {
        managed_rule_group_statement = null
        rate_based_statement         = null
        geo_match_statement = {
          country_codes = ["CN", "RU"]
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "GeoBlockRule"
        sampled_requests_enabled   = true
      }
    }
  ]

  environment = "prod"
  owner       = "security-team"
}
```

### WAF with Shield Advanced Protection

```hcl
module "waf_with_shield" {
  source = "../../modules/wafandshield"

  name  = "protected-web-acl"
  scope = "REGIONAL"

  enable_shield_protection = true
  shield_resource_arn      = aws_lb.main.arn

  environment = "prod"
  owner       = "platform-team"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the WAF Web ACL | `string` | n/a | yes |
| scope | Scope of the WAF Web ACL (REGIONAL or CLOUDFRONT) | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| owner | Owner or team responsible for the resource | `string` | n/a | yes |
| description | Description of the WAF Web ACL | `string` | `""` | no |
| rules | List of rules to add to the Web ACL | `list(object)` | `[]` | no |
| default_action | Default action for the Web ACL (allow or block) | `string` | `"allow"` | no |
| visibility_config | Visibility configuration for the Web ACL | `object` | See below | no |
| enable_shield_protection | Enable AWS Shield Advanced protection | `bool` | `false` | no |
| shield_resource_arn | ARN of the resource to protect with Shield | `string` | `""` | no |
| tags | Additional tags to apply to resources | `map(string)` | `{}` | no |

### Default Visibility Config

```hcl
{
  cloudwatch_metrics_enabled = true
  metric_name                = "waf-metrics"
  sampled_requests_enabled   = true
}
```

## Outputs

| Name | Description |
|------|-------------|
| web_acl_id | The ID of the WAF Web ACL |
| web_acl_arn | The ARN of the WAF Web ACL |
| web_acl_name | The name of the WAF Web ACL |
| web_acl_capacity | The capacity units used by the WAF Web ACL |
| web_acl_tags | The tags applied to the WAF Web ACL |
| shield_protection_id | The ID of the Shield protection (if enabled) |
| shield_protection_arn | The ARN of the Shield protection (if enabled) |
| visibility_config | The visibility configuration of the WAF Web ACL |

## OPA Policy Validation

This module includes comprehensive OPA policies that validate Terraform plans before deployment.

### CRITICAL Deny Rules

These rules will block deployment if violated:

1. **Missing Environment Tag**: WAF Web ACL must have an 'Environment' tag
2. **Missing Owner Tag**: WAF Web ACL must have an 'Owner' tag
3. **CloudWatch Metrics Disabled**: CloudWatch metrics must be enabled for security monitoring
4. **Sampled Requests Disabled**: Sampled requests must be enabled for security forensics
5. **Wildcard Characters in Name**: WAF Web ACL name cannot contain wildcard characters (*)

### WARNING Rules

These rules generate warnings but don't block deployment:

1. **No Rate Limiting**: Consider adding rate limiting rules to protect against DDoS attacks
2. **No AWS Managed Rules**: Consider using AWS Managed Rule Groups for common vulnerability protection
3. **No Geo-Blocking**: Consider adding geo-blocking rules to restrict access by geographic location
4. **Shield Advanced in Non-Prod**: AWS Shield Advanced is expensive and typically only justified for production environments

### Running Policy Validation

```bash
# Check policy syntax
opa check modules/wafandshield/policy/main.rego

# Run policy tests
opa test modules/wafandshield/policy/ -v

# Validate a Terraform plan
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
opa eval -d modules/wafandshield/policy/main.rego -i tfplan.json --fail "count(data.terraform.aws.wafandshield.deny) > 0"
```

## Examples

See the `environments/dev/services/wafandshield/` directory for a complete working example.

## License

This module is provided as-is for use in your infrastructure.

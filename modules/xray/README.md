# AWS X-Ray Terraform Module

This Terraform module provides a reusable configuration for deploying AWS X-Ray resources with integrated OPA policy validation. AWS X-Ray helps developers analyze and debug distributed applications by providing tools to view, filter, and gain insights into request data.

## Features

- **Sampling Rules**: Configure custom sampling rules to control what percentage of requests are traced
- **Encryption Support**: Enable encryption for trace data using KMS or AWS-managed keys
- **X-Ray Groups**: Create logical groupings of traces based on filter expressions
- **Tag Enforcement**: Automatic tagging with required tags (Environment, Owner) validated by OPA policies
- **Cost Optimization**: Default sampling rates and warnings for high-cost configurations
- **Flexible Configuration**: Support for multiple sampling rules and groups with customizable settings

## Requirements

- Terraform >= 1.4.0
- AWS Provider >= 5.0.0
- Valid AWS credentials with permissions to create X-Ray resources

## Usage

```hcl
module "xray" {
  source = "../../modules/xray"

  environment  = "dev"
  project_name = "my-project"

  tags = {
    Environment = "dev"
    Owner       = "platform-team"
    Project     = "my-project"
  }

  # Custom Sampling Rules
  sampling_rules = [
    {
      rule_name      = "api-high-priority"
      priority       = 100
      fixed_rate     = 0.10
      reservoir_size = 5
      url_path       = "/api/*"
      http_method    = "*"
      service_name   = "*"
      service_type   = "*"
      resource_arn   = "*"
    }
  ]

  # Default Sampling Rule
  create_default_sampling_rule = true
  default_sampling_rate        = 0.05
  default_reservoir_size       = 1

  # Encryption Configuration
  encryption_enabled = true
  encryption_type    = "KMS"
  encryption_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  # X-Ray Groups
  xray_groups = [
    {
      group_name        = "errors-group"
      filter_expression = "http.status >= 500"
      insights_enabled  = false
    },
    {
      group_name        = "slow-requests"
      filter_expression = "responsetime > 5"
      insights_enabled  = false
    }
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| project_name | Project name for resource naming | `string` | n/a | yes |
| tags | Common tags to apply to all resources. Must include Environment and Owner. | `map(string)` | `{}` | no |
| sampling_rules | List of X-Ray sampling rules to create | `list(object)` | `[]` | no |
| encryption_enabled | Enable encryption for X-Ray data | `bool` | `true` | no |
| encryption_type | Type of encryption (KMS or NONE) | `string` | `"KMS"` | no |
| encryption_key_id | KMS key ID for X-Ray encryption | `string` | `null` | no |
| xray_groups | List of X-Ray groups to create | `list(object)` | `[]` | no |
| create_default_sampling_rule | Create a default sampling rule | `bool` | `true` | no |
| default_sampling_rate | Default sampling rate (0.0 to 1.0) | `number` | `0.05` | no |
| default_reservoir_size | Default reservoir size for sampling | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| sampling_rule_ids | Map of sampling rule names to their IDs |
| sampling_rule_arns | Map of sampling rule names to their ARNs |
| sampling_rules | Map of all sampling rule attributes |
| encryption_config_id | ID of the encryption configuration |
| encryption_type | Type of encryption configured |
| encryption_key_id | KMS key ID used for encryption |
| group_ids | Map of group names to their IDs |
| group_arns | Map of group names to their ARNs |
| xray_groups | Map of all X-Ray group attributes |
| tags | Common tags applied to all resources |

## Sampling Rule Configuration

Sampling rules control what percentage of requests are traced. Each rule can target specific URL paths, HTTP methods, services, or hosts.

### Key Parameters

- **priority**: Lower numbers have higher priority (1-9999, with 10000 for default rule)
- **fixed_rate**: Percentage of requests to trace (0.0 to 1.0)
- **reservoir_size**: Number of requests per second to always trace
- **url_path**: URL path pattern to match (supports wildcards)
- **http_method**: HTTP method to match (GET, POST, etc., or * for all)
- **service_name**: Service name to match
- **service_type**: Service type to match

### Best Practices

- Use lower sampling rates (0.05-0.10) for high-traffic applications
- Set higher priorities (lower numbers) for critical paths
- Use reservoir_size to ensure a minimum number of traces
- Avoid 100% sampling rates in production (high cost)

## X-Ray Groups

Groups allow you to organize and filter traces based on specific criteria.

### Filter Expression Examples

- **Errors**: `http.status >= 500`
- **Slow requests**: `responsetime > 5`
- **Specific service**: `service(name = "my-api")`
- **Combined**: `http.status >= 500 OR responsetime > 5`

## Encryption

The module supports two encryption types:

1. **KMS**: Uses a customer-managed KMS key for enhanced security
2. **NONE**: Uses AWS-managed encryption

For production environments, KMS encryption is recommended.

## OPA Policy Validation

This module includes OPA policies that validate:

- **Required Tags**: Environment and Owner tags must be present
- **Encryption**: Encryption must be enabled when using X-Ray resources
- **Valid Configuration**: Groups must have non-empty filter expressions
- **Cost Warnings**: High sampling rates (>50%) trigger warnings

See `policy/README.md` for detailed policy documentation.

## Examples

### Minimal Configuration

```hcl
module "xray" {
  source = "../../modules/xray"

  environment  = "dev"
  project_name = "my-project"

  tags = {
    Environment = "dev"
    Owner       = "platform-team"
  }
}
```

### Production Configuration with Multiple Rules

```hcl
module "xray" {
  source = "../../modules/xray"

  environment  = "prod"
  project_name = "my-app"

  tags = {
    Environment = "prod"
    Owner       = "platform-team"
    CostCenter  = "engineering"
  }

  sampling_rules = [
    {
      rule_name      = "critical-api"
      priority       = 100
      fixed_rate     = 0.25
      reservoir_size = 10
      url_path       = "/api/critical/*"
    },
    {
      rule_name      = "general-api"
      priority       = 200
      fixed_rate     = 0.05
      reservoir_size = 1
      url_path       = "/api/*"
    }
  ]

  encryption_type = "KMS"
  encryption_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  xray_groups = [
    {
      group_name        = "production-errors"
      filter_expression = "http.status >= 500"
      insights_enabled  = true
    }
  ]
}
```

## License

This module is provided as-is for use within your organization.

## Authors

Platform Engineering Team

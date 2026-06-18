# AWS Secrets Manager Terraform Module

This Terraform module manages AWS Secrets Manager secrets with support for KMS encryption, automatic rotation, cross-region replication, resource policies, and comprehensive tagging.

## Features

- **Customer-Managed KMS Encryption**: Enforce encryption with customer-managed KMS keys for better security and audit control
- **Automatic Secret Rotation**: Configure Lambda-based automatic rotation with customizable schedules
- **Cross-Region Replication**: Replicate secrets to multiple regions for disaster recovery and multi-region applications
- **Resource-Based Policies**: Attach IAM resource policies to control access to secrets
- **Configurable Recovery Window**: Protect against accidental deletion with configurable recovery periods
- **Comprehensive Tagging**: Enforce required tags for governance and cost tracking
- **OPA Policy Validation**: Built-in OPA Rego policies enforce security best practices

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## Usage

### Basic Secret

```hcl
module "basic_secret" {
  source = "../../modules/secretsmanager"

  name        = "my-application-secret"
  description = "Database credentials for my application"
  kms_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  recovery_window_in_days = 30

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Application = "my-app"
  }
}
```

### Secret with Automatic Rotation

```hcl
module "rotated_secret" {
  source = "../../modules/secretsmanager"

  name        = "database-credentials"
  description = "RDS database master password"
  kms_key_id  = aws_kms_key.secrets.arn

  rotation_enabled    = true
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
  rotation_days       = 30

  recovery_window_in_days = 30

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Application = "database"
  }
}
```

### Secret with Cross-Region Replication

```hcl
module "replicated_secret" {
  source = "../../modules/secretsmanager"

  name        = "multi-region-secret"
  description = "Secret replicated across regions"
  kms_key_id  = aws_kms_key.primary.arn

  replica_regions = [
    {
      region     = "us-west-2"
      kms_key_id = aws_kms_key.replica_west.arn
    },
    {
      region     = "eu-west-1"
      kms_key_id = aws_kms_key.replica_eu.arn
    }
  ]

  recovery_window_in_days = 30

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Application = "global-app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the secret. Must be unique within the AWS account and region. | `string` | n/a | yes |
| description | Human-readable description of the secret. | `string` | `null` | no |
| kms_key_id | ARN or ID of the KMS key to use for encryption. If not specified, uses AWS managed key (not recommended for production). | `string` | `null` | no |
| recovery_window_in_days | Number of days that AWS Secrets Manager waits before deleting the secret. Set to 0 for immediate deletion (not recommended). | `number` | `30` | no |
| tags | Map of tags to assign to the secret. | `map(string)` | `{}` | no |
| rotation_enabled | Whether to enable automatic rotation for this secret. | `bool` | `false` | no |
| rotation_lambda_arn | ARN of the Lambda function that performs the rotation. Required if rotation_enabled is true. | `string` | `null` | no |
| rotation_days | Number of days between automatic rotations. | `number` | `30` | no |
| secret_string | Initial secret value as a string (e.g., JSON-encoded credentials). | `string` | `null` | no |
| secret_binary | Initial secret value as binary (base64-encoded). | `string` | `null` | no |
| policy | Resource-based policy JSON for the secret. | `string` | `null` | no |
| replica_regions | List of regions to replicate the secret to, with optional KMS key per region. | `list(object({ region = string, kms_key_id = optional(string) }))` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | ARN of the secret |
| secret_id | ID of the secret |
| secret_name | Name of the secret |
| version_id | Version ID of the current secret version |
| rotation_enabled | Whether rotation is enabled for this secret |
| replica_status | Map of replica regions and their status |

## OPA Policy Validation

This module includes OPA (Open Policy Agent) Rego policies that enforce security best practices:

### DENY Rules (Critical - Will Fail Pipeline)

- Secrets must use customer-managed KMS keys (not AWS managed keys)
- Secrets must have required tags: Environment, Owner, Application
- Secret resource policies must not use wildcard (*) principals
- Secrets must have recovery window > 0 days (no immediate deletion)

### WARN Rules (Informational)

- Secrets should have descriptions for documentation
- Consider enabling automatic rotation for critical secrets
- Recovery window should be >= 7 days for additional safety

## Notes

- **KMS Encryption**: AWS Secrets Manager supports two encryption options: AWS managed key (aws/secretsmanager) which is free and managed by AWS, or customer managed key which provides more control. OPA policies enforce customer-managed keys for production use.
- **Automatic Rotation**: Requires a Lambda function to perform rotation logic. AWS provides sample rotation functions for common scenarios (RDS, Redshift, etc.).
- **Cross-Region Replication**: Replicas are eventually consistent. Each replica can use a different KMS key for regional encryption.
- **Recovery Window**: Setting to 0 causes immediate deletion (dangerous). AWS default is 30 days. Policies enforce > 0 and recommend >= 7 days.

## License

See LICENSE file in the repository root.

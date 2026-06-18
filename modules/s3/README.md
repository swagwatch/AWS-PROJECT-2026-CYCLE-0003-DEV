# Terraform AWS S3 Module

A production-ready Terraform module for creating and managing AWS S3 buckets with built-in security best practices and compliance validation using OPA (Open Policy Agent).

## Features

- **Encryption at Rest**: Server-side encryption with SSE-S3 (AES256) or SSE-KMS encryption
- **Versioning**: Object versioning for data protection and recovery
- **Public Access Blocking**: Block all public access by default to prevent data exposure
- **Lifecycle Management**: Configurable lifecycle policies for cost optimization (transitions to IA/Glacier, expiration)
- **Access Logging**: S3 access logging for audit trails and compliance
- **Tagging Enforcement**: Required tags (Environment, Owner) enforced via OPA policies
- **Bucket Policies**: Optional bucket policies for fine-grained access control
- **Object Lock**: Optional object lock for compliance and regulatory requirements
- **Compliance Validation**: Built-in OPA policies to enforce security and compliance requirements

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

### AWS Permissions

The following AWS permissions are required to use this module:

- `s3:CreateBucket`
- `s3:DeleteBucket`
- `s3:PutBucketVersioning`
- `s3:PutEncryptionConfiguration`
- `s3:PutBucketPublicAccessBlock`
- `s3:PutLifecycleConfiguration`
- `s3:PutBucketLogging`
- `s3:PutBucketPolicy`
- `s3:PutBucketTagging`

## Usage

### Basic Example with Encryption and Versioning

```hcl
module "s3_bucket" {
  source = "./modules/s3"

  bucket_name = "my-app-data-bucket"

  encryption_configuration = {
    type = "AES256"
  }

  versioning_enabled = true

  public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "my-app"
  }
}
```

### Example with Lifecycle Rules for Archival

```hcl
module "s3_bucket_with_lifecycle" {
  source = "./modules/s3"

  bucket_name = "my-app-archive-bucket"

  encryption_configuration = {
    type = "AES256"
  }

  versioning_enabled = true

  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = "logs/"

      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "my-app"
  }
}
```

### Example with Logging Enabled

```hcl
module "s3_bucket_with_logging" {
  source = "./modules/s3"

  bucket_name = "my-app-data-bucket"

  encryption_configuration = {
    type = "AES256"
  }

  versioning_enabled = true

  logging_configuration = {
    target_bucket = "my-app-logs-bucket"
    target_prefix = "s3-access-logs/"
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "my-app"
  }
}
```

### Example with KMS Encryption

```hcl
module "s3_bucket_with_kms" {
  source = "./modules/s3"

  bucket_name = "my-app-secure-bucket"

  encryption_configuration = {
    type       = "aws:kms"
    kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }

  versioning_enabled = true

  public_access_block = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }

  tags = {
    Environment = "production"
    Owner       = "security-team"
    Project     = "my-app"
    Compliance  = "HIPAA"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket (must be globally unique) | `string` | n/a | yes |
| encryption_configuration | Server-side encryption configuration for the bucket | `object({ type = string, kms_key_id = optional(string) })` | `{ type = "AES256" }` | no |
| versioning_enabled | Enable versioning for the S3 bucket | `bool` | `true` | no |
| public_access_block | Public access block configuration for the bucket | `object({ block_public_acls = bool, block_public_policy = bool, ignore_public_acls = bool, restrict_public_buckets = bool })` | `{ block_public_acls = true, block_public_policy = true, ignore_public_acls = true, restrict_public_buckets = true }` | no |
| lifecycle_rules | List of lifecycle rules for the bucket | `list(object({ id = string, enabled = bool, prefix = optional(string), tags = optional(map(string)), expiration = optional(object({ days = number })), transitions = optional(list(object({ days = number, storage_class = string }))), noncurrent_version_expiration = optional(object({ days = number })), noncurrent_version_transitions = optional(list(object({ days = number, storage_class = string }))) }))` | `[]` | no |
| tags | Tags to apply to the S3 bucket (must include Environment and Owner) | `map(string)` | n/a | yes |
| logging_configuration | Access logging configuration for the bucket | `object({ target_bucket = string, target_prefix = string })` | `null` | no |
| force_destroy | Allow deletion of non-empty bucket | `bool` | `false` | no |
| object_lock_enabled | Enable object lock for compliance requirements | `bool` | `false` | no |
| bucket_policy | Optional bucket policy JSON | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket region-specific domain name |
| bucket_hosted_zone_id | The Route 53 Hosted Zone ID for this bucket's region |
| bucket_policy | The bucket policy JSON (if configured) |

## Notes

### AWS Provider v5.x Schema Changes

This module uses AWS provider >= 5.0.0 which introduced breaking changes to S3 resource structure. Specifically:

- Bucket encryption, versioning, logging, lifecycle rules, and public access blocking are now **separate resources** (`aws_s3_bucket_*`) instead of inline blocks on `aws_s3_bucket`
- This change improves resource management and reduces the risk of accidental bucket recreation

### S3 Bucket Naming

S3 bucket names must be globally unique across all AWS accounts. Consider using:

- Environment-specific prefixes (e.g., `dev-`, `staging-`, `prod-`)
- Account ID suffixes
- Random suffixes for additional uniqueness

### KMS Encryption Considerations

When using SSE-KMS encryption:

- The KMS key must exist before creating the bucket
- The KMS key must have appropriate permissions for the AWS principal creating the bucket
- This module does not create the KMS key - you must provide an existing key ARN

### Lifecycle Policy Best Practices

Implement lifecycle rules to reduce storage costs:

- Transition to `STANDARD_IA` after 90 days for infrequently accessed data
- Transition to `GLACIER` after 180 days for archival
- Set expiration policies for temporary data
- Use `INTELLIGENT_TIERING` for unpredictable access patterns

### Logging Bucket Requirements

When enabling S3 access logging:

- The target logging bucket must exist
- The target bucket must have appropriate bucket policies to allow log delivery
- The target bucket should be in the same region for performance and cost optimization
- **Never** log a bucket to itself (creates recursive logging)

### Tagging Strategy

Required tags enforced by OPA policies:

- `Environment`: The environment (e.g., dev, staging, production)
- `Owner`: The team or individual responsible for the bucket

Recommended additional tags:

- `Project`: The project or application name
- `CostCenter`: For cost allocation
- `Compliance`: Compliance requirements (e.g., HIPAA, PCI-DSS)

## License

This module is provided as-is for use in Terraform infrastructure deployments.

# AWS SNS Terraform Module

A production-ready Terraform module for deploying and managing AWS Simple Notification Service (SNS) topics and subscriptions with built-in security and compliance validation through OPA policies.

## Features

- **Standard and FIFO Topics**: Support for both standard and FIFO (First-In-First-Out) topics with content-based deduplication
- **KMS Encryption**: Server-side encryption using AWS KMS for data at rest
- **Flexible Subscriptions**: Support for multiple subscription protocols (SQS, Lambda, email, HTTP/HTTPS, SMS, etc.)
- **Access Control**: Custom topic policies for fine-grained access management
- **Delivery Policies**: Configurable message delivery retry policies
- **Comprehensive Tagging**: Automatic tagging with required tags (Environment, Owner, ManagedBy)
- **OPA Policy Validation**: Built-in security and compliance checks via Open Policy Agent

## Requirements

- Terraform >= 1.4.0
- AWS Provider >= 5.0.0
- OPA (Open Policy Agent) >= 0.50.0 (for policy validation)

## Usage

### Basic SNS Topic

```hcl
module "notifications" {
  source = "../../modules/sns"

  name        = "app-notifications"
  environment = "prod"
  owner       = "platform-team"

  kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  display_name      = "Application Notifications"

  tags = {
    Project = "core-infrastructure"
  }
}
```

### FIFO Topic with Encryption

```hcl
module "fifo_notifications" {
  source = "../../modules/sns"

  name        = "orders"
  environment = "prod"
  owner       = "orders-team"

  fifo_topic                  = true
  content_based_deduplication = true
  kms_master_key_id           = "alias/prod-sns-key"
  display_name                = "Order Processing Queue"

  tags = {
    Service = "order-processing"
  }
}
```

### Topic with Subscriptions

```hcl
module "notifications_with_subs" {
  source = "../../modules/sns"

  name        = "alerts"
  environment = "prod"
  owner       = "platform-team"

  kms_master_key_id = "alias/prod-sns-key"
  display_name      = "System Alerts"

  subscriptions = [
    {
      protocol = "sqs"
      endpoint = "arn:aws:sqs:us-east-1:123456789012:alert-queue"
      raw_message_delivery = true
    },
    {
      protocol = "lambda"
      endpoint = "arn:aws:lambda:us-east-1:123456789012:function:process-alerts"
    },
    {
      protocol = "email"
      endpoint = "ops-team@example.com"
    }
  ]

  tags = {
    CostCenter = "operations"
  }
}
```

### Topic with Custom Access Policy

```hcl
module "cross_account_topic" {
  source = "../../modules/sns"

  name        = "shared-notifications"
  environment = "prod"
  owner       = "platform-team"

  kms_master_key_id = "alias/prod-sns-key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::987654321098:root"
        }
        Action   = "sns:Publish"
        Resource = "*"
      }
    ]
  })

  tags = {
    Shared = "true"
  }
}
```

### Topic with Custom Delivery Policy

```hcl
module "reliable_notifications" {
  source = "../../modules/sns"

  name        = "critical-alerts"
  environment = "prod"
  owner       = "platform-team"

  kms_master_key_id = "alias/prod-sns-key"
  display_name      = "Critical System Alerts"

  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 300
        numRetries         = 10
        numMaxDelayRetries = 5
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "exponential"
      }
    }
  })

  tags = {
    Criticality = "high"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | The name of the SNS topic | `string` | n/a | yes |
| environment | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| owner | The owner of the SNS topic for tagging | `string` | n/a | yes |
| fifo_topic | Boolean indicating whether this is a FIFO topic | `bool` | `false` | no |
| content_based_deduplication | Enables content-based deduplication for FIFO topics | `bool` | `false` | no |
| kms_master_key_id | The ID or ARN of the AWS KMS key to use for encryption at rest | `string` | `null` | no |
| display_name | The display name for the SNS topic | `string` | `null` | no |
| delivery_policy | The SNS delivery policy as a JSON string | `string` | `null` | no |
| policy | The fully-formed AWS policy as a JSON string | `string` | `null` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| subscriptions | List of SNS topic subscriptions | `list(object)` | `[]` | no |

### Subscriptions Object

The `subscriptions` variable accepts a list of objects with the following attributes:

| Name | Description | Type | Required |
|------|-------------|------|----------|
| protocol | The subscription protocol (sqs, lambda, email, email-json, http, https, sms, etc.) | `string` | yes |
| endpoint | The subscription endpoint (ARN, URL, or email address) | `string` | yes |
| filter_policy | JSON string for message filtering | `string` | no |
| raw_message_delivery | Enable raw message delivery (for SQS/HTTP/S) | `bool` | no |
| confirmation_timeout_in_minutes | Timeout for subscription confirmation | `number` | no |

## Outputs

| Name | Description |
|------|-------------|
| topic_arn | The ARN of the SNS topic |
| topic_id | The ID of the SNS topic |
| topic_name | The name of the SNS topic |
| topic_owner | The AWS account ID of the SNS topic owner |
| subscription_arns | The ARNs of the SNS topic subscriptions |

## OPA Policy Validation

This module includes OPA policies that enforce security and compliance best practices. The policies are automatically validated during the commit process and CI/CD pipelines.

### CRITICAL Rules (Deny)

1. **KMS Encryption Required**: SNS topics must use KMS encryption (via `kms_master_key_id`)
2. **Required Tags**: Topics must have `Environment` and `Owner` tags
3. **No Wildcard Principals**: Topic policies must not use wildcard (`*`) principals
4. **FIFO Naming Convention**: FIFO topics must have names ending with `.fifo`

### WARNING Rules

1. **Display Name Recommended**: Consider setting `display_name` for better identification
2. **Delivery Policy Recommended**: Configure `delivery_policy` for retry control
3. **Subscription Confirmation**: Email/HTTP subscriptions require manual confirmation

### Running Policy Validation

```bash
# Check policy syntax
opa check modules/sns/policy/main.rego modules/sns/policy/test.rego

# Run policy tests
opa test modules/sns/policy/ -v

# Validate a Terraform plan
cd environments/dev
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > tfplan.json
opa eval -d opa-policies/service_sns_policies.rego -i tfplan.json --fail "count(data.terraform.aws.sns.deny) > 0"
```

## Best Practices

1. **Always Enable Encryption**: Use KMS encryption for topics handling sensitive data
2. **Use FIFO for Ordering**: When message order matters, use FIFO topics with content-based deduplication
3. **Tag Consistently**: Include required tags (Environment, Owner) plus application-specific tags
4. **Set Display Names**: Improves topic identification in AWS Console
5. **Configure Delivery Policies**: Customize retry behavior for critical notifications
6. **Limit Access**: Use specific IAM principals in topic policies, avoid wildcards
7. **Filter Messages**: Use subscription filter policies to reduce unnecessary deliveries
8. **Monitor Subscriptions**: Email/HTTP subscriptions require manual confirmation

## FIFO Topic Considerations

- FIFO topic names must end with `.fifo` suffix
- Maximum throughput: 300 messages/second (or 3,000 with batching)
- Messages are delivered exactly once and in order
- Content-based deduplication prevents duplicate messages within 5-minute window
- Message group IDs required for ordering within topic

## Subscription Protocol Support

| Protocol | Endpoint Format | Confirmation Required |
|----------|----------------|----------------------|
| sqs | SQS queue ARN | No |
| lambda | Lambda function ARN | No |
| email | Email address | Yes |
| email-json | Email address | Yes |
| http | HTTP URL | Yes |
| https | HTTPS URL | Yes |
| sms | Phone number | No |
| application | Mobile app endpoint ARN | No |
| firehose | Kinesis Firehose ARN | No |

## Examples

See the [examples](../../environments/dev/services/sns/) directory for complete working examples.

## Authors

Platform Team

## License

[Add your license here]

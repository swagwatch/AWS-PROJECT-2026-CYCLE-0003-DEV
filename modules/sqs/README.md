# AWS SQS Terraform Module

## Overview

This Terraform module provisions AWS Simple Queue Service (SQS) queues with comprehensive configuration options including encryption, dead-letter queue support, and customizable message handling parameters.

## Features

- **Standard and FIFO Queue Support**: Create both standard and FIFO queues with automatic naming conventions
- **KMS Encryption**: Server-side encryption using AWS KMS customer managed keys
- **Dead-Letter Queue Configuration**: Built-in support for DLQ with configurable max receive counts
- **Configurable Message Retention and Timeouts**: Customize visibility timeout, message retention, and delay settings
- **Required Tagging Enforcement**: Enforces Environment and Owner tags through variable validation
- **Queue Policy Support**: Optional IAM policy attachment for cross-account or service access control
- **Content-Based Deduplication**: Support for FIFO queue deduplication options

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## Usage

### Basic Standard Queue with Encryption

```hcl
module "sqs_queue" {
  source = "../../modules/sqs"

  queue_name        = "my-application-queue"
  kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### FIFO Queue with Dead-Letter Queue

```hcl
module "dlq" {
  source = "../../modules/sqs"

  queue_name        = "my-app-dlq"
  fifo_queue        = true
  kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}

module "primary_queue" {
  source = "../../modules/sqs"

  queue_name                  = "my-app-queue"
  fifo_queue                  = true
  content_based_deduplication = true
  kms_master_key_id           = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  dlq_arn                     = module.dlq.queue_arn
  max_receive_count           = 3

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### Queue with Custom Message Settings

```hcl
module "sqs_queue" {
  source = "../../modules/sqs"

  queue_name                 = "slow-processing-queue"
  kms_master_key_id          = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  visibility_timeout_seconds = 300  # 5 minutes
  message_retention_seconds  = 1209600  # 14 days
  receive_wait_time_seconds  = 20  # Enable long polling
  delay_seconds              = 30  # Delay all messages by 30 seconds

  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}
```

## Inputs

| Name | Type | Description | Default | Required |
|------|------|-------------|---------|----------|
| queue_name | string | The name of the SQS queue | - | yes |
| fifo_queue | bool | Boolean designating a FIFO queue | false | no |
| content_based_deduplication | bool | Enables content-based deduplication for FIFO queues | false | no |
| kms_master_key_id | string | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | null | no |
| kms_data_key_reuse_period_seconds | number | The length of time, in seconds, for which Amazon SQS can reuse a data key | 300 | no |
| visibility_timeout_seconds | number | The visibility timeout for the queue (0 to 43200 seconds) | 30 | no |
| message_retention_seconds | number | The number of seconds Amazon SQS retains a message (60 to 1209600 seconds) | 345600 | no |
| max_message_size | number | The limit of how many bytes a message can contain before Amazon SQS rejects it | 262144 | no |
| receive_wait_time_seconds | number | The time for which a ReceiveMessage call will wait for a message (long polling) | 0 | no |
| delay_seconds | number | The time in seconds that the delivery of all messages in the queue will be delayed | 0 | no |
| dlq_arn | string | The ARN of the dead-letter queue to which messages are moved after maxReceiveCount | null | no |
| max_receive_count | number | The number of times a message is delivered before being moved to the dead-letter queue | 5 | no |
| queue_policy | string | The JSON policy for the SQS queue | null | no |
| tags | map(string) | A map of tags to assign to the queue (must include Environment and Owner) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| queue_id | The URL for the created Amazon SQS queue |
| queue_arn | The ARN of the SQS queue |
| queue_url | The URL for the created Amazon SQS queue |
| queue_name | The name of the queue |

## Notes

### FIFO Queue Naming

FIFO queues must have names ending in `.fifo`. This module automatically appends the suffix when `fifo_queue = true`, so you should **not** include `.fifo` in the `queue_name` variable.

### KMS Key Permissions

The IAM role or user executing Terraform must have the following permissions on the KMS key specified in `kms_master_key_id`:

- `kms:Decrypt`
- `kms:GenerateDataKey`
- `kms:CreateGrant`

Additionally, the KMS key policy must allow SQS to use the key for encryption/decryption.

### Dead-Letter Queue Configuration

When configuring a DLQ:
1. The `dlq_arn` must point to an existing SQS queue
2. The DLQ should typically be created as a separate module instance before the main queue
3. Both queues must be of the same type (both standard or both FIFO)
4. The DLQ does not need to have a DLQ itself (no circular references)

### Message Retention Limits

AWS SQS supports message retention from 60 seconds (1 minute) to 1,209,600 seconds (14 days). The default is 345,600 seconds (4 days).

### FIFO Throughput

FIFO queues have lower throughput limits than standard queues:
- **Without batching**: 300 messages per second
- **With batching**: Up to 3,000 messages per second

Consider using standard queues if high throughput is required and message ordering is not critical.

### Content-Based Deduplication

When `content_based_deduplication = true` for FIFO queues, SQS uses a SHA-256 hash of the message body for deduplication. If disabled, your application must provide a message deduplication ID with each message.

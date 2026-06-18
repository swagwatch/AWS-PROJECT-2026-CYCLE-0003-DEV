package terraform.aws.s3_test

import data.terraform.aws.s3
import rego.v1

# Test 1: Valid S3 configuration with all security controls enabled
test_valid_s3_configuration_no_violations if {
  result := s3.deny with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.test",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["create"],
          "after": {
            "id": "test-bucket",
            "bucket": "test-bucket",
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team"
            }
          }
        }
      },
      {
        "address": "aws_s3_bucket_server_side_encryption_configuration.test",
        "type": "aws_s3_bucket_server_side_encryption_configuration",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "test-bucket",
            "rule": [
              {
                "apply_server_side_encryption_by_default": [
                  {
                    "sse_algorithm": "AES256"
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_versioning.test",
        "type": "aws_s3_bucket_versioning",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "test-bucket",
            "versioning_configuration": [
              {
                "status": "Enabled"
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_public_access_block.test",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "test-bucket",
            "block_public_acls": true,
            "block_public_policy": true,
            "ignore_public_acls": true,
            "restrict_public_buckets": true
          }
        }
      },
      {
        "address": "aws_s3_bucket_lifecycle_configuration.test",
        "type": "aws_s3_bucket_lifecycle_configuration",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "test-bucket",
            "rule": [
              {
                "id": "archive",
                "status": "Enabled",
                "transition": [
                  {
                    "days": 90,
                    "storage_class": "STANDARD_IA"
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_logging.test",
        "type": "aws_s3_bucket_logging",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "test-bucket",
            "target_bucket": "logs-bucket",
            "target_prefix": "s3-logs/"
          }
        }
      }
    ]
  }

  count(result) == 0
}

# Test 2: Invalid S3 configuration with multiple violations
test_invalid_s3_configuration_multiple_violations if {
  result := s3.deny with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.bad",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["create"],
          "after": {
            "id": "bad-bucket",
            "bucket": "bad-bucket",
            "tags": {}
          }
        }
      },
      {
        "address": "aws_s3_bucket_versioning.bad",
        "type": "aws_s3_bucket_versioning",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "bad-bucket",
            "versioning_configuration": [
              {
                "status": "Disabled"
              }
            ]
          }
        }
      }
    ]
  }

  count(result) > 3
}

# Test 3: Deleted resources should not trigger validations
test_s3_delete_action_ignored if {
  result := s3.deny with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.delete",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["delete"],
          "after": null,
          "before": {
            "id": "delete-bucket",
            "bucket": "delete-bucket"
          }
        }
      }
    ]
  }

  count(result) == 0
}

# Test 4: S3 bucket with KMS encryption is valid
test_s3_encryption_kms_valid if {
  result := s3.deny with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.kms",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["create"],
          "after": {
            "id": "kms-bucket",
            "bucket": "kms-bucket",
            "tags": {
              "Environment": "prod",
              "Owner": "security-team"
            }
          }
        }
      },
      {
        "address": "aws_s3_bucket_server_side_encryption_configuration.kms",
        "type": "aws_s3_bucket_server_side_encryption_configuration",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "kms-bucket",
            "rule": [
              {
                "apply_server_side_encryption_by_default": [
                  {
                    "sse_algorithm": "aws:kms",
                    "kms_master_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_versioning.kms",
        "type": "aws_s3_bucket_versioning",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "kms-bucket",
            "versioning_configuration": [
              {
                "status": "Enabled"
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_public_access_block.kms",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "kms-bucket",
            "block_public_acls": true,
            "block_public_policy": true,
            "ignore_public_acls": true,
            "restrict_public_buckets": true
          }
        }
      }
    ]
  }

  count(result) == 0
}

# Test 5: S3 bucket with all CRITICAL rules satisfied but missing logging and lifecycle (warnings only)
test_s3_warnings_only if {
  deny_result := s3.deny with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.warn",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["create"],
          "after": {
            "id": "warn-bucket",
            "bucket": "warn-bucket",
            "tags": {
              "Environment": "dev",
              "Owner": "dev-team"
            }
          }
        }
      },
      {
        "address": "aws_s3_bucket_server_side_encryption_configuration.warn",
        "type": "aws_s3_bucket_server_side_encryption_configuration",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "rule": [
              {
                "apply_server_side_encryption_by_default": [
                  {
                    "sse_algorithm": "AES256"
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_versioning.warn",
        "type": "aws_s3_bucket_versioning",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "versioning_configuration": [
              {
                "status": "Enabled"
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_public_access_block.warn",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "block_public_acls": true,
            "block_public_policy": true,
            "ignore_public_acls": true,
            "restrict_public_buckets": true
          }
        }
      }
    ]
  }

  warn_result := s3.warn with input as {
    "resource_changes": [
      {
        "address": "aws_s3_bucket.warn",
        "type": "aws_s3_bucket",
        "change": {
          "actions": ["create"],
          "after": {
            "id": "warn-bucket",
            "bucket": "warn-bucket",
            "tags": {
              "Environment": "dev",
              "Owner": "dev-team"
            }
          }
        }
      },
      {
        "address": "aws_s3_bucket_server_side_encryption_configuration.warn",
        "type": "aws_s3_bucket_server_side_encryption_configuration",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "rule": [
              {
                "apply_server_side_encryption_by_default": [
                  {
                    "sse_algorithm": "AES256"
                  }
                ]
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_versioning.warn",
        "type": "aws_s3_bucket_versioning",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "versioning_configuration": [
              {
                "status": "Enabled"
              }
            ]
          }
        }
      },
      {
        "address": "aws_s3_bucket_public_access_block.warn",
        "type": "aws_s3_bucket_public_access_block",
        "change": {
          "actions": ["create"],
          "after": {
            "bucket": "warn-bucket",
            "block_public_acls": true,
            "block_public_policy": true,
            "ignore_public_acls": true,
            "restrict_public_buckets": true
          }
        }
      }
    ]
  }

  count(deny_result) == 0
  count(warn_result) > 0
}

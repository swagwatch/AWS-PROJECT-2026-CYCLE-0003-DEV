package terraform.aws.xray

import data.terraform.aws.xray

# Helper to count items
count(arr) = n if {
  n := sum([1 | arr[_]])
}

# Valid configuration test: should have no denies and possibly zero warns
test_valid_xray_config if {
  # Valid X-Ray configuration with all required tags and proper settings
  test_input := {
    "resource_changes": [
      {
        "address": "module.xray.aws_xray_sampling_rule.this[\"test-dev-default-sampling\"]",
        "type": "aws_xray_sampling_rule",
        "change": {
          "actions": ["create"],
          "after": {
            "rule_name": "test-dev-default-sampling",
            "priority": 10000,
            "fixed_rate": 0.05,
            "reservoir_size": 1,
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Module": "xray",
              "ManagedBy": "Terraform"
            }
          }
        }
      },
      {
        "address": "module.xray.aws_xray_encryption_config.this[0]",
        "type": "aws_xray_encryption_config",
        "change": {
          "actions": ["create"],
          "after": {
            "type": "KMS",
            "key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
        }
      },
      {
        "address": "module.xray.aws_xray_group.this[\"test-errors\"]",
        "type": "aws_xray_group",
        "change": {
          "actions": ["create"],
          "after": {
            "group_name": "test-errors",
            "filter_expression": "responsetime > 5 OR http.status >= 500",
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Module": "xray",
              "ManagedBy": "Terraform"
            }
          }
        }
      }
    ]
  }

  # Should have zero deny violations
  deny_count := count(xray.deny) with input as test_input
  deny_count == 0
}

# Invalid configuration test: multiple violations expected
test_invalid_xray_config if {
  # Invalid X-Ray configuration missing required tags and no encryption
  test_input := {
    "resource_changes": [
      {
        "address": "module.xray.aws_xray_sampling_rule.this[\"test-sampling\"]",
        "type": "aws_xray_sampling_rule",
        "change": {
          "actions": ["create"],
          "after": {
            "rule_name": "test-sampling",
            "priority": 100,
            "fixed_rate": 1.0,
            "reservoir_size": 1,
            "tags": {
              "Module": "xray"
            }
          }
        }
      },
      {
        "address": "module.xray.aws_xray_group.this[\"test-group\"]",
        "type": "aws_xray_group",
        "change": {
          "actions": ["create"],
          "after": {
            "group_name": "test-group",
            "filter_expression": "responsetime > 5",
            "tags": {
              "Module": "xray"
            }
          }
        }
      }
    ]
  }

  # Should have multiple deny violations
  deny_count := count(xray.deny) with input as test_input
  deny_count > 0

  # Should have violations for missing Environment tag
  env_violations := [msg | msg := xray.deny[_] with input as test_input; contains(msg, "Environment")]
  count(env_violations) > 0

  # Should have violations for missing Owner tag
  owner_violations := [msg | msg := xray.deny[_] with input as test_input; contains(msg, "Owner")]
  count(owner_violations) > 0

  # Should have violation for missing encryption config
  encryption_violations := [msg | msg := xray.deny[_] with input as test_input; contains(msg, "encryption")]
  count(encryption_violations) > 0

  # Should have warnings for 100% sampling rate
  warn_count := count(xray.warn) with input as test_input
  warn_count > 0
}

# Edge case: Deleted resources should not trigger validations
test_deleted_resources_ignored if {
  # Resources being deleted should not trigger violations
  test_input := {
    "resource_changes": [
      {
        "address": "module.xray.aws_xray_sampling_rule.this[\"test-sampling\"]",
        "type": "aws_xray_sampling_rule",
        "change": {
          "actions": ["delete"],
          "before": {
            "rule_name": "test-sampling",
            "priority": 100,
            "fixed_rate": 0.05,
            "reservoir_size": 1
          },
          "after": null
        }
      },
      {
        "address": "module.xray.aws_xray_group.this[\"test-group\"]",
        "type": "aws_xray_group",
        "change": {
          "actions": ["delete"],
          "before": {
            "group_name": "test-group",
            "filter_expression": "responsetime > 5"
          },
          "after": null
        }
      }
    ]
  }

  # Should have zero deny violations for deleted resources
  deny_count := count(xray.deny) with input as test_input
  deny_count == 0

  # Should have zero warn violations for deleted resources
  warn_count := count(xray.warn) with input as test_input
  warn_count == 0
}


package terraform.aws.sqs

import data.terraform.aws.sqs

# Helper to count items
count(arr) = n if {
  n := sum([1 | arr[_]])
}

# Valid configuration test: should have no denies and possibly zero warns
test_valid_configuration_no_violations if {
  mock_input := {
    "resource_changes": [{
      "address": "aws_sqs_queue.test",
      "type": "aws_sqs_queue",
      "change": {
        "actions": ["create"],
        "after": {
          "kms_master_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
          "visibility_timeout_seconds": 30,
          "message_retention_seconds": 345600,
          "tags": {
            "Environment": "dev",
            "Owner": "platform-team"
          }
        }
      }
    }]
  }

  deny_violations := data.terraform.aws.sqs.deny with input as mock_input
  count(deny_violations) == 0
}

# Invalid configuration test: multiple violations expected
test_invalid_configuration_with_violations if {
  mock_input := {
    "resource_changes": [{
      "address": "aws_sqs_queue.test",
      "type": "aws_sqs_queue",
      "change": {
        "actions": ["create"],
        "after": {
          "visibility_timeout_seconds": 30,
          "message_retention_seconds": 345600,
          "tags": {}
        }
      }
    }]
  }

  deny_violations := data.terraform.aws.sqs.deny with input as mock_input
  count(deny_violations) == 3  # no encryption + missing Environment tag + missing Owner tag
}

# Edge case: Deleted resources should not trigger validations
test_delete_action_ignored if {
  mock_input := {
    "resource_changes": [{
      "address": "aws_sqs_queue.test",
      "type": "aws_sqs_queue",
      "change": {
        "actions": ["delete"],
        "after": null
      }
    }]
  }

  deny_violations := data.terraform.aws.sqs.deny with input as mock_input
  count(deny_violations) == 0
}

# Wildcard policy violation test
test_wildcard_policy_violation if {
  mock_input := {
    "resource_changes": [{
      "address": "aws_sqs_queue_policy.test",
      "type": "aws_sqs_queue_policy",
      "change": {
        "actions": ["create"],
        "after": {
          "policy": "{\"Statement\":[{\"Principal\":\"*\",\"Effect\":\"Allow\",\"Action\":\"sqs:*\"}]}"
        }
      }
    }]
  }

  deny_violations := data.terraform.aws.sqs.deny with input as mock_input
  count(deny_violations) > 0
}


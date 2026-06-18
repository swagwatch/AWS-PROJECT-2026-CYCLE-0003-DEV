package terraform.aws.secretsmanager

import data.terraform.aws.secretsmanager

# Helper to count items
count(arr) = n if {
  n := sum([1 | arr[_]])
}

# Valid configuration test: should have no denies and possibly zero warns
test_valid_configuration_no_violations if {
	input_plan := {
		"resource_changes": [{
			"address": "aws_secretsmanager_secret.valid",
			"type": "aws_secretsmanager_secret",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "my-valid-secret",
					"description": "A properly configured secret",
					"kms_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"recovery_window_in_days": 30,
					"policy": null,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
						"Application": "my-app",
					},
				},
			},
		}],
	}

	count(deny) with input as input_plan == 0
}

# Invalid configuration test: multiple violations expected
test_invalid_configuration_with_violations if {
	input_plan := {
		"resource_changes": [{
			"address": "aws_secretsmanager_secret.invalid",
			"type": "aws_secretsmanager_secret",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "my-invalid-secret",
					"description": null,
					"kms_key_id": null,
					"recovery_window_in_days": 0,
					"policy": null,
					"tags": {"Environment": "dev"},
				},
			},
		}],
	}

	violations := deny with input as input_plan
	count(violations) == 4
}

# Edge case: Deleted resources should not trigger validations
test_delete_action_ignored if {
	input_plan := {
		"resource_changes": [{
			"address": "aws_secretsmanager_secret.deleted",
			"type": "aws_secretsmanager_secret",
			"change": {
				"actions": ["delete"],
				"after": null,
			},
		}],
	}

	count(deny) with input as input_plan == 0
}


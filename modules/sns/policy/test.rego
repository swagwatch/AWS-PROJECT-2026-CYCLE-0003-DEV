package terraform.aws.sns

import rego.v1

# Test 1: Valid configuration - should have no deny violations
test_valid_configuration_no_violations if {
	test_input := {
		"resource_changes": [{
			"address": "aws_sns_topic.test",
			"type": "aws_sns_topic",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "test-topic",
					"fifo_topic": false,
					"kms_master_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"display_name": "Test Topic",
					"delivery_policy": "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20}}}",
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}

	count(deny) == 0 with input as test_input
}

# Test 2: Invalid configuration - multiple CRITICAL violations
test_invalid_configuration_with_violations if {
	test_input := {
		"resource_changes": [
			{
				"address": "aws_sns_topic.bad",
				"type": "aws_sns_topic",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "bad-topic",
						"fifo_topic": false,
						"kms_master_key_id": null,
						"display_name": null,
						"delivery_policy": null,
						"tags": {},
					},
				},
			},
			{
				"address": "aws_sns_topic.bad_fifo",
				"type": "aws_sns_topic",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "bad-topic-without-suffix",
						"fifo_topic": true,
						"kms_master_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "aws_sns_topic_policy.bad_policy",
				"type": "aws_sns_topic_policy",
				"change": {
					"actions": ["create"],
					"after": {"policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"sns:Publish\"}]}"},
				},
			},
		],
	}

	# Should have at least 4 violations:
	# 1. Missing kms_master_key_id on bad-topic
	# 2. Missing Environment tag on bad-topic
	# 3. Missing Owner tag on bad-topic
	# 4. FIFO topic without .fifo suffix
	# 5. Wildcard principal in policy
	count(deny) >= 4 with input as test_input
}

# Test 3: Deleted resources - should NOT trigger violations
test_delete_action_ignored if {
	test_input := {
		"resource_changes": [{
			"address": "aws_sns_topic.deleted",
			"type": "aws_sns_topic",
			"change": {
				"actions": ["delete"],
				"after": {
					"name": "deleted-topic",
					"fifo_topic": false,
					"kms_master_key_id": null,
					"tags": {},
				},
			},
		}],
	}

	# Deleted resources should not trigger deny rules
	count(deny) == 0 with input as test_input
}

# Test 4: FIFO topic with correct suffix - should pass
test_fifo_topic_with_correct_suffix if {
	test_input := {
		"resource_changes": [{
			"address": "aws_sns_topic.fifo_good",
			"type": "aws_sns_topic",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "good-topic.fifo",
					"fifo_topic": true,
					"kms_master_key_id": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
					"tags": {
						"Environment": "prod",
						"Owner": "team-a",
					},
				},
			},
		}],
	}

	count(deny) == 0 with input as test_input
}

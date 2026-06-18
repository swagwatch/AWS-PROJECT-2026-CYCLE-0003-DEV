package terraform.aws.cloudwatch

import rego.v1

# Test 1: Valid configuration with all best practices should have no violations
test_valid_configuration_no_violations if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_cloudwatch_log_group.app_logs",
				"type": "aws_cloudwatch_log_group",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "/aws/application/app",
						"retention_in_days": 30,
						"kms_key_id": null,
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "aws_cloudwatch_metric_alarm.high_cpu",
				"type": "aws_cloudwatch_metric_alarm",
				"change": {
					"actions": ["create"],
					"after": {
						"alarm_name": "high-cpu-alarm",
						"comparison_operator": "GreaterThanThreshold",
						"evaluation_periods": 2,
						"metric_name": "CPUUtilization",
						"namespace": "AWS/EC2",
						"period": 300,
						"statistic": "Average",
						"threshold": 80,
						"alarm_actions": ["arn:aws:sns:us-east-1:123456789012:alerts"],
					},
				},
			},
		],
	}

	violations := deny with input as mock_input
	count(violations) == 0
}

# Test 2: Invalid configuration with multiple violations
test_invalid_configuration_with_violations if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_cloudwatch_log_group.bad_logs",
				"type": "aws_cloudwatch_log_group",
				"change": {
					"actions": ["create"],
					"after": {
						"name": "/aws/application/bad",
						"retention_in_days": null,
						"kms_key_id": null,
						"tags": {},
					},
				},
			},
			{
				"address": "aws_cloudwatch_metric_alarm.bad_alarm",
				"type": "aws_cloudwatch_metric_alarm",
				"change": {
					"actions": ["create"],
					"after": {
						"alarm_name": "bad-alarm",
						"comparison_operator": "GreaterThanThreshold",
						"evaluation_periods": 1,
						"metric_name": "CPUUtilization",
						"namespace": "AWS/EC2",
						"period": 300,
						"statistic": "Average",
						"threshold": 80,
						"alarm_actions": [],
						"ok_actions": [],
						"insufficient_data_actions": [],
					},
				},
			},
		],
	}

	violations := deny with input as mock_input
	# Expect violations for:
	# 1. Missing retention policy
	# 2. Missing Environment tag
	# 3. Missing Owner tag
	# 4. Alarm with no actions
	# 5. Alarm with evaluation_periods < 2
	count(violations) >= 5
}

# Test 3: Deleted resources should not trigger validations
test_delete_action_ignored if {
	mock_input := {
		"resource_changes": [
			{
				"address": "aws_cloudwatch_log_group.deleted_logs",
				"type": "aws_cloudwatch_log_group",
				"change": {
					"actions": ["delete"],
					"after": null,
				},
			},
			{
				"address": "aws_cloudwatch_metric_alarm.deleted_alarm",
				"type": "aws_cloudwatch_metric_alarm",
				"change": {
					"actions": ["delete"],
					"after": null,
				},
			},
		],
	}

	violations := deny with input as mock_input
	count(violations) == 0
}

# Test 4: Production environment requires KMS encryption
test_production_requires_kms_encryption if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_cloudwatch_log_group.prod_logs",
			"type": "aws_cloudwatch_log_group",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "/aws/application/prod",
					"retention_in_days": 90,
					"kms_key_id": null,
					"tags": {
						"Environment": "production",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}

	violations := deny with input as mock_input
	# Should have violation for missing KMS encryption in production
	count(violations) >= 1

	# Verify the violation message mentions KMS encryption
	some violation in violations
	contains(violation.message, "KMS encryption")
}

# Test 5: Warn rules for retention periods
test_warn_short_retention if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_cloudwatch_log_group.short_retention",
			"type": "aws_cloudwatch_log_group",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "/aws/application/short",
					"retention_in_days": 3,
					"kms_key_id": null,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}

	warnings := warn with input as mock_input
	# Should have warning for short retention period
	count(warnings) >= 1
}

# Test 6: Retention set to 0 should trigger deny
test_zero_retention_denied if {
	mock_input := {
		"resource_changes": [{
			"address": "aws_cloudwatch_log_group.zero_retention",
			"type": "aws_cloudwatch_log_group",
			"change": {
				"actions": ["create"],
				"after": {
					"name": "/aws/application/zero",
					"retention_in_days": 0,
					"kms_key_id": null,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}

	violations := deny with input as mock_input
	# Should have violation for retention set to 0
	count(violations) >= 1

	# Verify the violation message mentions indefinite retention
	some violation in violations
	contains(violation.message, "indefinite")
}

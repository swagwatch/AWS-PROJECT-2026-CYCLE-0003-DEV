package terraform.aws.cloudwatch

# Evaluate Terraform plan JSON (terraform show -json plan.tfplan)
# Provides:
# - deny: CRITICAL violations that must fail the pipeline
# - warn: non-blocking warnings
# - info: informational findings

# Helper: return resource changes for a given type that are created or updated
resource_changes_by_type(res_type) := array.concat(creates, updates) if {
	creates := [rc |
		rc := input.resource_changes[_]
		rc.type == res_type
		actions := rc.change.actions
		array_contains(actions, "create")
	]
	updates := [rc |
		rc := input.resource_changes[_]
		rc.type == res_type
		actions := rc.change.actions
		array_contains(actions, "update")
	]
}

# Helper: get tags from after object
get_tags(after) = tags_out if {
	tags := after.tags
	tags_out := tags
} else = tags_all_out if {
	tags_all := after.tags_all
	tags_all_out := tags_all
} else = {} if {
	true
}

# Helper: check if a list contains a value
array_contains(arr, v) if {
	some i
	arr[i] == v
}

# ------------------------
# DENY Rules (Security Best Practices - CRITICAL)
# ------------------------

# DENY: Log groups must have retention policies set
deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after

	# Check if retention_in_days is missing, null, or zero
	retention := object.get(after, "retention_in_days", null)
	retention == null

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' must have a retention policy set. Set retention_in_days to prevent indefinite log storage and excessive costs.",
			[log_group.address],
		),
	}
}

deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after

	# Check if retention_in_days is zero
	retention := object.get(after, "retention_in_days", null)
	retention == 0

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' has retention set to 0 (indefinite). Set a specific retention period to prevent excessive costs.",
			[log_group.address],
		),
	}
}

# DENY: Log groups must have required tags (Environment and Owner)
deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after
	tags := get_tags(after)

	# Check for Environment tag
	environment := object.get(tags, "Environment", "")
	environment == ""

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' is missing required tag 'Environment'. Add Environment tag for cost allocation and compliance.",
			[log_group.address],
		),
	}
}

deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after
	tags := get_tags(after)

	# Check for Owner tag
	owner := object.get(tags, "Owner", "")
	owner == ""

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' is missing required tag 'Owner'. Add Owner tag for accountability and resource management.",
			[log_group.address],
		),
	}
}

# DENY: Production log groups must use KMS encryption
deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after
	tags := get_tags(after)

	# Check if this is a production environment
	environment := object.get(tags, "Environment", "")
	lower(environment) == "production"

	# Check if KMS encryption is missing (null or empty string)
	kms_key_id := object.get(after, "kms_key_id", null)
	kms_key_id == null

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' in production environment must use KMS encryption. Set kms_key_id to encrypt logs at rest.",
			[log_group.address],
		),
	}
}

deny contains violation if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after
	tags := get_tags(after)

	# Check if this is a production environment
	environment := object.get(tags, "Environment", "")
	lower(environment) == "production"

	# Check if KMS encryption is empty string
	kms_key_id := object.get(after, "kms_key_id", null)
	kms_key_id == ""

	violation := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' in production environment must use KMS encryption. Set kms_key_id to encrypt logs at rest.",
			[log_group.address],
		),
	}
}

# DENY: Metric alarms must have at least one action configured
deny contains violation if {
	alarms := resource_changes_by_type("aws_cloudwatch_metric_alarm")
	some alarm in alarms
	after := alarm.change.after

	# Get all action lists
	alarm_actions := object.get(after, "alarm_actions", [])
	ok_actions := object.get(after, "ok_actions", [])
	insufficient_data_actions := object.get(after, "insufficient_data_actions", [])

	# Check if all action lists are empty
	count(alarm_actions) == 0
	count(ok_actions) == 0
	count(insufficient_data_actions) == 0

	violation := {
		"resource": alarm.address,
		"message": sprintf(
			"CloudWatch Metric Alarm '%s' has no actions configured. Configure alarm_actions, ok_actions, or insufficient_data_actions to make the alarm actionable.",
			[alarm.address],
		),
	}
}

# DENY: Metric alarms must have sufficient evaluation periods
deny contains violation if {
	alarms := resource_changes_by_type("aws_cloudwatch_metric_alarm")
	some alarm in alarms
	after := alarm.change.after

	# Check if evaluation_periods is less than 2
	evaluation_periods := object.get(after, "evaluation_periods", 0)
	evaluation_periods < 2

	violation := {
		"resource": alarm.address,
		"message": sprintf(
			"CloudWatch Metric Alarm '%s' has evaluation_periods set to %d. Use at least 2 evaluation periods to prevent flapping alerts.",
			[alarm.address, evaluation_periods],
		),
	}
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: Log groups with very short retention periods may cause data loss
warn contains warning if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after

	retention := object.get(after, "retention_in_days", null)
	retention != null
	retention < 7
	retention > 0

	warning := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' has very short retention period (%d days). Consider at least 7 days for troubleshooting and investigations.",
			[log_group.address, retention],
		),
	}
}

# WARN: Log groups with very long retention periods may incur excessive costs
warn contains warning if {
	log_groups := resource_changes_by_type("aws_cloudwatch_log_group")
	some log_group in log_groups
	after := log_group.change.after

	retention := object.get(after, "retention_in_days", null)
	retention != null
	retention > 365

	warning := {
		"resource": log_group.address,
		"message": sprintf(
			"CloudWatch Log Group '%s' has long retention period (%d days). Consider shorter retention or archiving to S3 for cost optimization.",
			[log_group.address, retention],
		),
	}
}

# WARN: Metric alarms without alarm_actions won't notify anyone
warn contains warning if {
	alarms := resource_changes_by_type("aws_cloudwatch_metric_alarm")
	some alarm in alarms
	after := alarm.change.after

	alarm_actions := object.get(after, "alarm_actions", [])
	count(alarm_actions) == 0

	# Only warn if there are other actions but no alarm_actions
	ok_actions := object.get(after, "ok_actions", [])
	insufficient_data_actions := object.get(after, "insufficient_data_actions", [])
	count(ok_actions) + count(insufficient_data_actions) > 0

	warning := {
		"resource": alarm.address,
		"message": sprintf(
			"CloudWatch Metric Alarm '%s' has no alarm_actions configured. Consider adding SNS topic notification for alarm states.",
			[alarm.address],
		),
	}
}

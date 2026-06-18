package terraform.aws.sns

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

# DENY: SNS topics must use KMS encryption in production environments
deny contains msg if {
	rc := resource_changes_by_type("aws_sns_topic")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	# Check if kms_master_key_id is missing or empty
	not after.kms_master_key_id

	msg := sprintf("CRITICAL: SNS topic '%s' must use KMS encryption. Specify kms_master_key_id for encryption at rest. Resource: %s", [after.name, rc.address])
}

# DENY: Required tags must be present (Environment and Owner)
deny contains msg if {
	rc := resource_changes_by_type("aws_sns_topic")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	tags := get_tags(after)
	required_tags := ["Environment", "Owner"]
	missing_tag := required_tags[_]
	not tags[missing_tag]

	msg := sprintf("CRITICAL: Missing required tag '%s' on SNS topic '%s'. Resource: %s", [missing_tag, after.name, rc.address])
}

# DENY: SNS topic access policies must not use wildcard principal
deny contains msg if {
	rc := resource_changes_by_type("aws_sns_topic_policy")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	# Parse the policy JSON string
	policy := json.unmarshal(after.policy)

	# Check for wildcard principal in any statement
	statement := policy.Statement[_]
	statement.Principal == "*"

	msg := sprintf("CRITICAL: SNS topic policy must not use wildcard principal '*'. Use specific AWS accounts/roles for better security. Resource: %s", [rc.address])
}

# DENY: SNS topic access policies must not have Principal.AWS with wildcard
deny contains msg if {
	rc := resource_changes_by_type("aws_sns_topic_policy")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	policy := json.unmarshal(after.policy)
	statement := policy.Statement[_]

	# Check for wildcard in Principal.AWS
	principal_aws := statement.Principal.AWS
	is_string(principal_aws)
	principal_aws == "*"

	msg := sprintf("CRITICAL: SNS topic policy must not use wildcard principal in Principal.AWS. Use specific AWS accounts/roles. Resource: %s", [rc.address])
}

# DENY: FIFO topics must have names ending with .fifo suffix
deny contains msg if {
	rc := resource_changes_by_type("aws_sns_topic")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	after.fifo_topic == true
	not endswith(after.name, ".fifo")

	msg := sprintf("CRITICAL: FIFO topic '%s' must have a name ending with '.fifo' suffix. Resource: %s", [after.name, rc.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: Display name is recommended for better topic identification
warn contains msg if {
	rc := resource_changes_by_type("aws_sns_topic")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	not after.display_name

	msg := sprintf("WARNING: Consider setting display_name for SNS topic '%s' for better identification in AWS console. Resource: %s", [after.name, rc.address])
}

# WARN: Delivery policy is recommended for controlling message delivery retries
warn contains msg if {
	rc := resource_changes_by_type("aws_sns_topic")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	not after.delivery_policy

	msg := sprintf("WARNING: Consider configuring delivery_policy for SNS topic '%s' to control message delivery retries and backoff. Resource: %s", [after.name, rc.address])
}

# WARN: Email and HTTP subscriptions require manual confirmation
warn contains msg if {
	rc := resource_changes_by_type("aws_sns_topic_subscription")[_]
	not array_contains(rc.change.actions, "delete")
	after := rc.change.after

	# Check for protocols that require confirmation
	confirmation_required_protocols := ["email", "email-json", "http", "https"]
	array_contains(confirmation_required_protocols, after.protocol)

	msg := sprintf("WARNING: SNS subscription with protocol '%s' requires manual confirmation after creation. Endpoint: %s, Resource: %s", [after.protocol, after.endpoint, rc.address])
}

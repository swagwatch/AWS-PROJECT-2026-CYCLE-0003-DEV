package terraform.aws.secretsmanager

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

# DENY: Secrets must use customer-managed KMS keys (when kms_key_id is null)
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if kms_key_id is null
	after.kms_key_id == null

	msg := sprintf("DENY: Secret '%s' must use customer-managed KMS key for encryption. Specify kms_key_id. (Resource: %s)", [after.name, secret.address])
}

# DENY: Secrets must have required tags
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after
	tags := get_tags(after)

	required_tags := ["Environment", "Owner", "Application"]
	missing_tag := required_tags[_]
	not tags[missing_tag]

	msg := sprintf("DENY: Missing required tag '%s' on secret '%s'. (Resource: %s)", [missing_tag, after.name, secret.address])
}

# DENY: Secret policies must not use wildcard principals (string wildcard)
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if policy is defined and not null
	after.policy

	# Parse policy JSON
	policy := json.unmarshal(after.policy)
	statement := policy.Statement[_]
	principal := statement.Principal

	# Check for string wildcard
	principal == "*"

	msg := sprintf("DENY: Secret '%s' policy must not use wildcard (*) in Principal. Restrict access to specific principals. (Resource: %s)", [after.name, secret.address])
}

# DENY: Secret policies must not use wildcard principals (AWS string wildcard)
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if policy is defined and not null
	after.policy

	# Parse policy JSON
	policy := json.unmarshal(after.policy)
	statement := policy.Statement[_]
	principal := statement.Principal

	# Check for AWS wildcard (when Principal.AWS is a string)
	is_string(principal.AWS)
	principal.AWS == "*"

	msg := sprintf("DENY: Secret '%s' policy must not use wildcard (*) in Principal.AWS. Restrict access to specific principals. (Resource: %s)", [after.name, secret.address])
}

# DENY: Secret policies must not use wildcard principals (AWS array wildcard)
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if policy is defined and not null
	after.policy

	# Parse policy JSON
	policy := json.unmarshal(after.policy)
	statement := policy.Statement[_]
	principal := statement.Principal

	# Check for AWS wildcard (when Principal.AWS is an array)
	is_array(principal.AWS)
	array_contains(principal.AWS, "*")

	msg := sprintf("DENY: Secret '%s' policy must not use wildcard (*) in Principal.AWS array. Restrict access to specific principals. (Resource: %s)", [after.name, secret.address])
}

# DENY: Secrets must have recovery window > 0 days
deny contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if recovery_window_in_days is 0 (immediate deletion)
	after.recovery_window_in_days == 0

	msg := sprintf("DENY: Secret '%s' must have recovery window > 0 days. Immediate deletion (0) is not allowed for safety. (Resource: %s)", [after.name, secret.address])
}

# ------------------------
# WARN Rules (Best Practices)
# ------------------------

# WARN: Secrets should have descriptions
warn contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if description is missing or empty
	not after.description

	msg := sprintf("WARN: Secret '%s' should have a description for documentation purposes. (Resource: %s)", [after.name, secret.address])
}

warn contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if description is empty string
	after.description == ""

	msg := sprintf("WARN: Secret '%s' should have a description for documentation purposes. (Resource: %s)", [after.name, secret.address])
}

# WARN: Automatic rotation should be enabled for critical secrets
warn contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if there's no rotation resource for this secret
	rotations := resource_changes_by_type("aws_secretsmanager_secret_rotation")
	rotation_secret_ids := [r.change.after.secret_id | r := rotations[_]]
	secret_id := after.id

	# If secret_id is not set yet (during creation), we need to check by reference
	# For warnings, we'll just check if rotation resources exist at all
	count(rotations) == 0

	msg := sprintf("WARN: Consider enabling automatic rotation for critical secrets. Secret '%s' does not have rotation configured. (Resource: %s)", [after.name, secret.address])
}

# WARN: Recovery window should be >= 7 days
warn contains msg if {
	secrets := resource_changes_by_type("aws_secretsmanager_secret")
	count(secrets) > 0
	secret := secrets[_]
	after := secret.change.after

	# Check if recovery window is less than 7 days (but not 0, as that's a DENY)
	after.recovery_window_in_days < 7
	after.recovery_window_in_days > 0

	msg := sprintf("WARN: Recovery window of %d days is short for secret '%s'. Consider >= 7 days for safety. (Resource: %s)", [after.recovery_window_in_days, after.name, secret.address])
}

package terraform.aws.sqs

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

# Rule: SQS queue must be encrypted with KMS
deny contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue")[_]
  after := rc.change.after
  not after.kms_master_key_id
  msg := sprintf("SQS queue must be encrypted with KMS. Specify kms_master_key_id. Resource: %s", [rc.address])
}

# Rule: SQS queue must have required tag 'Environment'
deny contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue")[_]
  tags := get_tags(rc.change.after)
  not tags.Environment
  msg := sprintf("Missing required tag 'Environment' on SQS queue. Resource: %s", [rc.address])
}

# Rule: SQS queue must have required tag 'Owner'
deny contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue")[_]
  tags := get_tags(rc.change.after)
  not tags.Owner
  msg := sprintf("Missing required tag 'Owner' on SQS queue. Resource: %s", [rc.address])
}

# Rule: SQS queue policy must not use wildcard principal
deny contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue_policy")[_]
  policy_str := rc.change.after.policy
  policy := json.unmarshal(policy_str)
  statement := policy.Statement[_]
  principal := statement.Principal

  # Check for Principal: "*"
  principal == "*"

  msg := sprintf("SQS queue policy must not use wildcard principal '*'. Specify explicit principals. Resource: %s", [rc.address])
}

# Rule: SQS queue policy must not use wildcard principal (AWS format)
deny contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue_policy")[_]
  policy_str := rc.change.after.policy
  policy := json.unmarshal(policy_str)
  statement := policy.Statement[_]
  principal := statement.Principal

  # Check for Principal: {"AWS": "*"}
  is_object(principal)
  aws_principal := principal.AWS
  aws_principal == "*"

  msg := sprintf("SQS queue policy must not use wildcard principal '*'. Specify explicit principals. Resource: %s", [rc.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# Rule: High visibility timeout warning
warn contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue")[_]
  after := rc.change.after
  after.visibility_timeout_seconds > 300
  msg := sprintf("Visibility timeout is high (>5 minutes). Review if necessary to avoid message processing delays. Resource: %s", [rc.address])
}

# Rule: High message retention warning
warn contains msg if {
  rc := resource_changes_by_type("aws_sqs_queue")[_]
  after := rc.change.after
  after.message_retention_seconds > 1209600
  msg := sprintf("Message retention is high (>14 days). Consider shorter retention to reduce storage costs. Resource: %s", [rc.address])
}

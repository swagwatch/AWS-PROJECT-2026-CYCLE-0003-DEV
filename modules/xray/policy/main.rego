package terraform.aws.xray

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

# Deny: X-Ray Sampling Rules must have required tags (Environment and Owner)
deny contains msg if {
  sampling_rules := resource_changes_by_type("aws_xray_sampling_rule")
  rc := sampling_rules[_]
  tags := get_tags(rc.change.after)

  not tags.Environment

  msg := sprintf("CRITICAL: X-Ray sampling rule '%s' is missing required tag 'Environment'", [rc.address])
}

deny contains msg if {
  sampling_rules := resource_changes_by_type("aws_xray_sampling_rule")
  rc := sampling_rules[_]
  tags := get_tags(rc.change.after)

  not tags.Owner

  msg := sprintf("CRITICAL: X-Ray sampling rule '%s' is missing required tag 'Owner'", [rc.address])
}

# Deny: X-Ray Groups must have required tags (Environment and Owner)
deny contains msg if {
  groups := resource_changes_by_type("aws_xray_group")
  rc := groups[_]
  tags := get_tags(rc.change.after)

  not tags.Environment

  msg := sprintf("CRITICAL: X-Ray group '%s' is missing required tag 'Environment'", [rc.address])
}

deny contains msg if {
  groups := resource_changes_by_type("aws_xray_group")
  rc := groups[_]
  tags := get_tags(rc.change.after)

  not tags.Owner

  msg := sprintf("CRITICAL: X-Ray group '%s' is missing required tag 'Owner'", [rc.address])
}

# Deny: X-Ray encryption must be enabled
deny contains msg if {
  # Check if there are any X-Ray sampling rules or groups being created
  sampling_rules := resource_changes_by_type("aws_xray_sampling_rule")
  groups := resource_changes_by_type("aws_xray_group")

  # If we have X-Ray resources, we must have encryption config
  count(sampling_rules) + count(groups) > 0

  # Check if encryption config exists
  encryption_configs := resource_changes_by_type("aws_xray_encryption_config")
  count(encryption_configs) == 0

  msg := "CRITICAL: X-Ray encryption configuration must be enabled when using X-Ray resources"
}

# Deny: X-Ray Groups must have valid filter expressions
deny contains msg if {
  groups := resource_changes_by_type("aws_xray_group")
  rc := groups[_]
  filter := rc.change.after.filter_expression

  # Filter expression must not be empty
  filter == ""

  msg := sprintf("CRITICAL: X-Ray group '%s' has an empty filter_expression", [rc.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# Warn: High sampling rates can increase costs
warn contains msg if {
  sampling_rules := resource_changes_by_type("aws_xray_sampling_rule")
  rc := sampling_rules[_]
  fixed_rate := rc.change.after.fixed_rate

  fixed_rate > 0.5

  msg := sprintf("WARNING: X-Ray sampling rule '%s' has a high fixed_rate (%.2f). Consider reducing for cost optimization", [rc.address, fixed_rate])
}

# Warn: Sampling rate of 100% is typically not recommended
warn contains msg if {
  sampling_rules := resource_changes_by_type("aws_xray_sampling_rule")
  rc := sampling_rules[_]
  fixed_rate := rc.change.after.fixed_rate

  fixed_rate == 1.0

  msg := sprintf("WARNING: X-Ray sampling rule '%s' has 100%% sampling rate. This will trace all requests and may significantly increase costs", [rc.address])
}

# Warn: Encryption should use KMS for better security
warn contains msg if {
  encryption_configs := resource_changes_by_type("aws_xray_encryption_config")
  rc := encryption_configs[_]
  enc_type := rc.change.after.type

  enc_type != "KMS"

  msg := sprintf("WARNING: X-Ray encryption config '%s' is not using KMS encryption. Consider using KMS for enhanced security", [rc.address])
}

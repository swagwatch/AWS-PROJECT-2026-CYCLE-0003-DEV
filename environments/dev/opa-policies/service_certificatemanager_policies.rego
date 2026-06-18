package terraform.aws.certificatemanager

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

# CRITICAL: Certificates must have required tags (Environment, Owner, Project)
deny contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  tags := get_tags(resource.change.after)

  required_tags := ["Environment", "Owner", "Project"]
  missing_tags := [tag | tag := required_tags[_]; not tags[tag]]
  count(missing_tags) > 0

  msg := sprintf(
    "CRITICAL: Certificate '%s' is missing required tags: %s. All certificates must have Environment, Owner, and Project tags for compliance.",
    [resource.address, concat(", ", missing_tags)]
  )
}

# CRITICAL: Certificates must use DNS validation (EMAIL validation is deprecated)
deny contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  validation_method := resource.change.after.validation_method
  validation_method == "EMAIL"

  msg := sprintf(
    "CRITICAL: Certificate '%s' uses EMAIL validation. Use DNS validation for automated renewal and security. EMAIL validation is deprecated.",
    [resource.address]
  )
}

# CRITICAL: Certificate transparency logging must be enabled
deny contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  logging_preference := resource.change.after.options[0].certificate_transparency_logging_preference
  logging_preference == "DISABLED"

  msg := sprintf(
    "CRITICAL: Certificate '%s' has certificate transparency logging disabled. Transparency logging is required for auditability and compliance.",
    [resource.address]
  )
}

# CRITICAL: Certificates must use secure key algorithms (no RSA_1024 or weak algorithms)
deny contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  key_algorithm := resource.change.after.key_algorithm

  # Allowed algorithms: RSA_2048, RSA_4096, EC_prime256v1, EC_secp384r1
  allowed_algorithms := ["RSA_2048", "RSA_4096", "EC_prime256v1", "EC_secp384r1"]
  not array_contains(allowed_algorithms, key_algorithm)

  msg := sprintf(
    "CRITICAL: Certificate '%s' uses weak or unsupported key algorithm '%s'. Use RSA_2048, RSA_4096, EC_prime256v1, or EC_secp384r1.",
    [resource.address, key_algorithm]
  )
}

# CRITICAL: Certificate domain names must not be empty
deny contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  domain_name := resource.change.after.domain_name
  domain_name == ""

  msg := sprintf(
    "CRITICAL: Certificate '%s' has an empty domain name. A valid domain name is required.",
    [resource.address]
  )
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: Wildcard certificates may have security implications
warn contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  domain_name := resource.change.after.domain_name
  startswith(domain_name, "*.")

  msg := sprintf(
    "WARNING: Certificate '%s' uses a wildcard domain '%s'. Consider using specific domain names with SANs for better security granularity.",
    [resource.address, domain_name]
  )
}

# WARN: Consider using subject alternative names instead of multiple certificates
warn contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  sans := resource.change.after.subject_alternative_names
  count(sans) == 0

  not startswith(resource.change.after.domain_name, "*.")

  msg := sprintf(
    "INFO: Certificate '%s' has no subject alternative names. Consider adding SANs if multiple domains need SSL/TLS coverage.",
    [resource.address]
  )
}

# WARN: Large number of SANs may indicate architectural issues
warn contains msg if {
  resource := resource_changes_by_type("aws_acm_certificate")[_]
  sans := resource.change.after.subject_alternative_names
  count(sans) > 50

  msg := sprintf(
    "WARNING: Certificate '%s' has %d subject alternative names. Consider splitting into multiple certificates for better management.",
    [resource.address, count(sans)]
  )
}

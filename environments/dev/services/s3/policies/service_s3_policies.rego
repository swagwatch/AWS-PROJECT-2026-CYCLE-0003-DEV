package terraform.aws.s3

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

# DENY: S3 bucket must have server-side encryption enabled
deny contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  # Get all encryption configurations
  encryption_configs := resource_changes_by_type("aws_s3_bucket_server_side_encryption_configuration")

  # Check if this bucket has an encryption configuration
  bucket_has_encryption := [enc |
    enc := encryption_configs[_]
    enc.change.after.bucket == bucket.change.after.id
  ]

  count(bucket_has_encryption) == 0

  msg := {
    "msg": sprintf("S3 bucket '%s' does not have server-side encryption enabled. Add aws_s3_bucket_server_side_encryption_configuration resource.", [bucket.address]),
    "resource": bucket.address,
    "severity": "CRITICAL"
  }
}

# DENY: S3 bucket encryption must use AES256 (SSE-S3) or aws:kms (SSE-KMS)
deny contains msg if {
  encryption_configs := resource_changes_by_type("aws_s3_bucket_server_side_encryption_configuration")
  some i
  enc := encryption_configs[i]

  sse_algorithm := enc.change.after.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm

  not array_contains(["AES256", "aws:kms"], sse_algorithm)

  msg := {
    "msg": sprintf("S3 bucket encryption configuration '%s' uses invalid algorithm '%s'. Must use 'AES256' (SSE-S3) or 'aws:kms' (SSE-KMS).", [enc.address, sse_algorithm]),
    "resource": enc.address,
    "severity": "CRITICAL"
  }
}

# DENY: S3 bucket must have versioning enabled
deny contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  # Get all versioning configurations
  versioning_configs := resource_changes_by_type("aws_s3_bucket_versioning")

  # Check if this bucket has versioning enabled
  bucket_has_versioning_enabled := [ver |
    ver := versioning_configs[_]
    ver.change.after.bucket == bucket.change.after.id
    ver.change.after.versioning_configuration[0].status == "Enabled"
  ]

  count(bucket_has_versioning_enabled) == 0

  msg := {
    "msg": sprintf("S3 bucket '%s' does not have versioning enabled. Set versioning_configuration.status to 'Enabled' in aws_s3_bucket_versioning resource.", [bucket.address]),
    "resource": bucket.address,
    "severity": "CRITICAL"
  }
}

# DENY: S3 bucket must block all public access
deny contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  # Get all public access block configurations
  public_access_blocks := resource_changes_by_type("aws_s3_bucket_public_access_block")

  # Check if this bucket has proper public access blocking
  bucket_has_public_access_blocked := [pab |
    pab := public_access_blocks[_]
    pab.change.after.bucket == bucket.change.after.id
    pab.change.after.block_public_acls == true
    pab.change.after.block_public_policy == true
    pab.change.after.ignore_public_acls == true
    pab.change.after.restrict_public_buckets == true
  ]

  count(bucket_has_public_access_blocked) == 0

  msg := {
    "msg": sprintf("S3 bucket '%s' does not block all public access. All four settings (block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets) must be true in aws_s3_bucket_public_access_block resource.", [bucket.address]),
    "resource": bucket.address,
    "severity": "CRITICAL"
  }
}

# DENY: S3 bucket must have required tags (Environment and Owner)
deny contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  tags := get_tags(bucket.change.after)

  not tags.Environment

  msg := {
    "msg": sprintf("S3 bucket '%s' is missing required tag 'Environment'. Add Environment tag to the bucket.", [bucket.address]),
    "resource": bucket.address,
    "severity": "CRITICAL"
  }
}

deny contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  tags := get_tags(bucket.change.after)

  not tags.Owner

  msg := {
    "msg": sprintf("S3 bucket '%s' is missing required tag 'Owner'. Add Owner tag to the bucket.", [bucket.address]),
    "resource": bucket.address,
    "severity": "CRITICAL"
  }
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: S3 bucket should have lifecycle rules to reduce storage costs
warn contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  # Get all lifecycle configurations
  lifecycle_configs := resource_changes_by_type("aws_s3_bucket_lifecycle_configuration")

  # Check if this bucket has lifecycle configuration
  bucket_has_lifecycle := [lc |
    lc := lifecycle_configs[_]
    lc.change.after.bucket == bucket.change.after.id
  ]

  count(bucket_has_lifecycle) == 0

  msg := {
    "msg": sprintf("S3 bucket '%s' does not have lifecycle rules configured. Consider adding lifecycle rules to transition objects to IA/Glacier for cost optimization.", [bucket.address]),
    "resource": bucket.address,
    "severity": "WARNING"
  }
}

# WARN: S3 bucket should have access logging enabled for audit trails
warn contains msg if {
  s3_buckets := resource_changes_by_type("aws_s3_bucket")
  some i
  bucket := s3_buckets[i]

  # Get all logging configurations
  logging_configs := resource_changes_by_type("aws_s3_bucket_logging")

  # Check if this bucket has logging enabled
  bucket_has_logging := [log |
    log := logging_configs[_]
    log.change.after.bucket == bucket.change.after.id
  ]

  count(bucket_has_logging) == 0

  msg := {
    "msg": sprintf("S3 bucket '%s' does not have access logging enabled. Consider enabling logging for audit trails and compliance.", [bucket.address]),
    "resource": bucket.address,
    "severity": "WARNING"
  }
}

# WARN: S3 bucket should use intelligent tiering or lifecycle transitions for cost optimization
warn contains msg if {
  lifecycle_configs := resource_changes_by_type("aws_s3_bucket_lifecycle_configuration")
  some i
  lc := lifecycle_configs[i]

  # Check if any rule has transitions
  has_transitions := [rule |
    rule := lc.change.after.rule[_]
    count(rule.transition) > 0
  ]

  count(has_transitions) == 0

  msg := {
    "msg": sprintf("S3 bucket lifecycle configuration '%s' does not include any storage class transitions. Consider adding transitions to STANDARD_IA, INTELLIGENT_TIERING, or GLACIER for cost optimization.", [lc.address]),
    "resource": lc.address,
    "severity": "WARNING"
  }
}

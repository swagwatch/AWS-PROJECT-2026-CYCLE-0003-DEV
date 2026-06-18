package terraform.aws.rds_aurora

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

# CRITICAL: Encryption at rest must be enabled
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  not after.storage_encrypted
  msg := sprintf("RDS Aurora cluster '%s' must have encryption at rest enabled (storage_encrypted = true)", [rc.address])
}

# CRITICAL: Deletion protection must be enabled for production environments
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  not after.deletion_protection
  msg := sprintf("RDS Aurora cluster '%s' must have deletion protection enabled for production environments", [rc.address])
}

# CRITICAL: Backup retention period must be at least 7 days
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  after.backup_retention_period < 7
  msg := sprintf("RDS Aurora cluster '%s' must have backup retention period of at least 7 days (current: %d)", [rc.address, after.backup_retention_period])
}

# CRITICAL: IAM database authentication should be enabled for enhanced security
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  not after.iam_database_authentication_enabled
  msg := sprintf("RDS Aurora cluster '%s' should enable IAM database authentication for enhanced security", [rc.address])
}

# CRITICAL: Required tags must be present (Environment, Owner)
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  tags := get_tags(after)
  not tags.Environment
  msg := sprintf("RDS Aurora cluster '%s' must have 'Environment' tag", [rc.address])
}

deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  tags := get_tags(after)
  not tags.Owner
  msg := sprintf("RDS Aurora cluster '%s' must have 'Owner' tag", [rc.address])
}

# CRITICAL: RDS Aurora instances must not be publicly accessible
deny contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster_instance")[_]
  after := rc.change.after
  after.publicly_accessible == true
  msg := sprintf("RDS Aurora instance '%s' must not be publicly accessible", [rc.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARNING: Multi-AZ deployment recommended for high availability
warn contains msg if {
  cluster := resource_changes_by_type("aws_rds_cluster")[_]
  instances := resource_changes_by_type("aws_rds_cluster_instance")
  count(instances) < 2
  msg := sprintf("RDS Aurora cluster '%s' should have at least 2 instances for high availability (current: %d)", [cluster.address, count(instances)])
}

# WARNING: Performance Insights should be enabled for monitoring
warn contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster_instance")[_]
  after := rc.change.after
  not after.performance_insights_enabled
  msg := sprintf("RDS Aurora instance '%s' should enable Performance Insights for monitoring", [rc.address])
}

# WARNING: Enhanced monitoring should be enabled
warn contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster_instance")[_]
  after := rc.change.after
  after.monitoring_interval == 0
  msg := sprintf("RDS Aurora instance '%s' should enable enhanced monitoring (monitoring_interval > 0)", [rc.address])
}

# WARNING: CloudWatch logs should be exported
warn contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster")[_]
  after := rc.change.after
  count(after.enabled_cloudwatch_logs_exports) == 0
  msg := sprintf("RDS Aurora cluster '%s' should export logs to CloudWatch", [rc.address])
}

# WARNING: Consider using non-burstable instance classes for production workloads
warn contains msg if {
  rc := resource_changes_by_type("aws_rds_cluster_instance")[_]
  after := rc.change.after
  startswith(after.instance_class, "db.t")
  msg := sprintf("RDS Aurora instance '%s' uses burstable instance class '%s'. Consider using non-burstable instance classes (db.r*, db.m*) for production workloads", [rc.address, after.instance_class])
}

package terraform.aws.rds_aurora

import rego.v1

# Test 1: Valid Configuration - should pass all CRITICAL rules
test_valid_configuration if {
	deny with input as {
		"resource_changes": [
			{
				"address": "module.rds_aurora.aws_rds_cluster.this",
				"type": "aws_rds_cluster",
				"change": {
					"actions": ["create"],
					"after": {
						"storage_encrypted": true,
						"deletion_protection": true,
						"backup_retention_period": 7,
						"iam_database_authentication_enabled": true,
						"enabled_cloudwatch_logs_exports": ["audit", "error", "general", "slowquery"],
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "module.rds_aurora.aws_rds_cluster_instance.this[0]",
				"type": "aws_rds_cluster_instance",
				"change": {
					"actions": ["create"],
					"after": {
						"publicly_accessible": false,
						"instance_class": "db.r5.large",
						"performance_insights_enabled": true,
						"monitoring_interval": 60,
					},
				},
			},
			{
				"address": "module.rds_aurora.aws_rds_cluster_instance.this[1]",
				"type": "aws_rds_cluster_instance",
				"change": {
					"actions": ["create"],
					"after": {
						"publicly_accessible": false,
						"instance_class": "db.r5.large",
						"performance_insights_enabled": true,
						"monitoring_interval": 60,
					},
				},
			},
		],
	}
	count(deny) == 0
}

# Test 2: Missing Encryption - should trigger CRITICAL violation
test_missing_encryption if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["create"],
				"after": {
					"storage_encrypted": false,
					"deletion_protection": true,
					"backup_retention_period": 7,
					"iam_database_authentication_enabled": true,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(violations) > 0
	some violation in violations
	contains(violation, "encryption")
}

# Test 3: Missing Required Tags - should trigger CRITICAL violations
test_missing_tags if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["create"],
				"after": {
					"storage_encrypted": true,
					"deletion_protection": true,
					"backup_retention_period": 7,
					"iam_database_authentication_enabled": true,
					"tags": {},
				},
			},
		}],
	}
	count(violations) >= 2
	some violation in violations
	contains(violation, "Environment")
	some other_violation in violations
	contains(other_violation, "Owner")
}

# Test 4: Publicly Accessible Instance - should trigger CRITICAL violation
test_publicly_accessible if {
	violations := deny with input as {
		"resource_changes": [
			{
				"address": "module.rds_aurora.aws_rds_cluster.this",
				"type": "aws_rds_cluster",
				"change": {
					"actions": ["create"],
					"after": {
						"storage_encrypted": true,
						"deletion_protection": true,
						"backup_retention_period": 7,
						"iam_database_authentication_enabled": true,
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "module.rds_aurora.aws_rds_cluster_instance.this[0]",
				"type": "aws_rds_cluster_instance",
				"change": {
					"actions": ["create"],
					"after": {"publicly_accessible": true},
				},
			},
		],
	}
	count(violations) > 0
	some violation in violations
	contains(violation, "publicly accessible")
}

# Test 5: Low Backup Retention - should trigger CRITICAL violation
test_low_backup_retention if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["create"],
				"after": {
					"storage_encrypted": true,
					"deletion_protection": true,
					"backup_retention_period": 1,
					"iam_database_authentication_enabled": true,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(violations) > 0
	some violation in violations
	contains(violation, "backup retention")
}

# Test 6: Delete Action Ignored - should not trigger violations
test_delete_action_ignored if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["delete"],
				"after": null,
			},
		}],
	}
	count(violations) == 0
}

# Test 7: Warning Rules - Single Instance Configuration
test_single_instance_warning if {
	warnings := warn with input as {
		"resource_changes": [
			{
				"address": "module.rds_aurora.aws_rds_cluster.this",
				"type": "aws_rds_cluster",
				"change": {
					"actions": ["create"],
					"after": {
						"storage_encrypted": true,
						"deletion_protection": true,
						"backup_retention_period": 7,
						"iam_database_authentication_enabled": true,
						"enabled_cloudwatch_logs_exports": [],
						"tags": {
							"Environment": "dev",
							"Owner": "platform-team",
						},
					},
				},
			},
			{
				"address": "module.rds_aurora.aws_rds_cluster_instance.this[0]",
				"type": "aws_rds_cluster_instance",
				"change": {
					"actions": ["create"],
					"after": {
						"publicly_accessible": false,
						"instance_class": "db.t3.medium",
						"performance_insights_enabled": false,
						"monitoring_interval": 0,
					},
				},
			},
		],
	}
	count(warnings) > 0
}

# Test 8: No Deletion Protection - should trigger CRITICAL violation
test_no_deletion_protection if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["create"],
				"after": {
					"storage_encrypted": true,
					"deletion_protection": false,
					"backup_retention_period": 7,
					"iam_database_authentication_enabled": true,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(violations) > 0
	some violation in violations
	contains(violation, "deletion protection")
}

# Test 9: No IAM Authentication - should trigger CRITICAL violation
test_no_iam_authentication if {
	violations := deny with input as {
		"resource_changes": [{
			"address": "module.rds_aurora.aws_rds_cluster.this",
			"type": "aws_rds_cluster",
			"change": {
				"actions": ["create"],
				"after": {
					"storage_encrypted": true,
					"deletion_protection": true,
					"backup_retention_period": 7,
					"iam_database_authentication_enabled": false,
					"tags": {
						"Environment": "dev",
						"Owner": "platform-team",
					},
				},
			},
		}],
	}
	count(violations) > 0
	some violation in violations
	contains(violation, "IAM")
}

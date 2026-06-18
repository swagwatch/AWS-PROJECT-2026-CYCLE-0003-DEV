# Cluster Identification
cluster_identifier = "dev-aurora-cluster"

# Engine Configuration
engine                            = "aurora-mysql"
engine_version                    = "8.0.mysql_aurora.3.04.0"
engine_mode                       = "provisioned"
db_cluster_parameter_group_family = "aurora-mysql8.0"

# Instance Configuration
instance_class = "db.t3.medium"
instance_count = 2

# Database Configuration
database_name               = "devdb"
master_username             = "admin"
master_password             = null # Should be provided via environment variable or secrets manager
manage_master_user_password = true # Let AWS manage the password in Secrets Manager

# Networking
subnet_ids = [
  "subnet-0123456789abcdef0", # Replace with actual subnet IDs
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2"
]
vpc_security_group_ids = [
  "sg-0123456789abcdef0" # Replace with actual security group ID
]
publicly_accessible = false

# Backup & Recovery
backup_retention_period   = 7
preferred_backup_window   = "03:00-04:00"
skip_final_snapshot       = false
final_snapshot_identifier = null # Will be auto-generated

# Encryption
storage_encrypted = true
kms_key_id        = null # Use default AWS managed key, or provide KMS key ARN

# High Availability
deletion_protection          = true
preferred_maintenance_window = "sun:05:00-sun:06:00"

# Monitoring
enabled_cloudwatch_logs_exports       = ["audit", "error", "general", "slowquery"]
performance_insights_enabled          = true
performance_insights_retention_period = 7
performance_insights_kms_key_id       = null
monitoring_interval                   = 60
monitoring_role_arn                   = null # Will be auto-created

# Authentication
iam_database_authentication_enabled = true

# Parameter Groups
cluster_parameters  = []
instance_parameters = []

# Tags
tags = {
  Environment = "dev"
  Owner       = "platform-team"
  Project     = "aurora-rds"
}
environment = "dev"
owner       = "platform-team"

# Additional Configuration
apply_immediately          = false
auto_minor_version_upgrade = true
copy_tags_to_snapshot      = true

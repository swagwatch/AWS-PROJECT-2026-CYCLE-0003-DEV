# Cluster Identification
variable "cluster_identifier" {
  description = "The cluster identifier for the RDS Aurora cluster"
  type        = string
}

# Engine Configuration
variable "engine" {
  description = "The database engine to use (aurora-mysql or aurora-postgresql)"
  type        = string
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "engine_mode" {
  description = "The database engine mode (provisioned or serverless)"
  type        = string
}

variable "db_cluster_parameter_group_family" {
  description = "The family of the DB cluster parameter group"
  type        = string
}

# Instance Configuration
variable "instance_class" {
  description = "The instance class to use for Aurora instances"
  type        = string
}

variable "instance_count" {
  description = "Number of Aurora instances to create in the cluster"
  type        = number
}

# Database Configuration
variable "database_name" {
  description = "Name for an automatically created database on cluster creation"
  type        = string
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "master_password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
}

# Networking
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the cluster"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the instances are publicly accessible"
  type        = bool
}

# Backup & Recovery
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created"
  type        = string
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before deletion"
  type        = bool
}

variable "final_snapshot_identifier" {
  description = "The name of the final snapshot when the cluster is deleted"
  type        = string
}

# Encryption
variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key"
  type        = string
}

# High Availability
variable "deletion_protection" {
  description = "If true, the DB cluster cannot be deleted"
  type        = bool
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur"
  type        = string
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled"
  type        = bool
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data"
  type        = number
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected"
  type        = number
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
}

# Authentication
variable "iam_database_authentication_enabled" {
  description = "Specifies whether IAM Database authentication is enabled"
  type        = bool
}

# Parameter Groups
variable "cluster_parameters" {
  description = "List of cluster parameter group parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
}

variable "instance_parameters" {
  description = "List of instance parameter group parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for the resource"
  type        = string
}

# Additional Configuration
variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately"
  type        = bool
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically"
  type        = bool
}

variable "copy_tags_to_snapshot" {
  description = "Copy all cluster tags to snapshots"
  type        = bool
}

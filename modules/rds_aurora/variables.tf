# Cluster Identification
variable "cluster_identifier" {
  description = "The cluster identifier for the RDS Aurora cluster"
  type        = string
}

# Engine Configuration
variable "engine" {
  description = "The database engine to use (aurora-mysql or aurora-postgresql)"
  type        = string
  default     = "aurora-mysql"

  validation {
    condition     = contains(["aurora-mysql", "aurora-postgresql"], var.engine)
    error_message = "Engine must be either 'aurora-mysql' or 'aurora-postgresql'."
  }
}

variable "engine_version" {
  description = "The engine version to use"
  type        = string
}

variable "engine_mode" {
  description = "The database engine mode (provisioned or serverless)"
  type        = string
  default     = "provisioned"

  validation {
    condition     = contains(["provisioned", "serverless"], var.engine_mode)
    error_message = "Engine mode must be either 'provisioned' or 'serverless'."
  }
}

# Instance Configuration
variable "instance_class" {
  description = "The instance class to use for Aurora instances"
  type        = string
  default     = "db.t3.medium"
}

variable "instance_count" {
  description = "Number of Aurora instances to create in the cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1
    error_message = "Instance count must be at least 1."
  }
}

# Database Configuration
variable "database_name" {
  description = "Name for an automatically created database on cluster creation"
  type        = string
  default     = null
}

variable "master_username" {
  description = "Username for the master DB user"
  type        = string
}

variable "master_password" {
  description = "Password for the master DB user (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
  default     = null
}

variable "manage_master_user_password" {
  description = "Set to true to allow RDS to manage the master user password in Secrets Manager"
  type        = bool
  default     = false
}

# Networking
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (must span at least 2 AZs)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the cluster"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the instances are publicly accessible"
  type        = bool
  default     = false
}

# Backup & Recovery
variable "backup_retention_period" {
  description = "The days to retain backups for (1-35 days)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created (e.g., 03:00-04:00)"
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before deletion"
  type        = bool
  default     = false
}

variable "final_snapshot_identifier" {
  description = "The name of the final snapshot when the cluster is deleted"
  type        = string
  default     = null
}

# Encryption
variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key (if storage_encrypted is true)"
  type        = string
  default     = null
}

# High Availability
variable "deletion_protection" {
  description = "If true, the DB cluster cannot be deleted"
  type        = bool
  default     = true
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur (e.g., sun:05:00-sun:06:00)"
  type        = string
  default     = null
}

# Monitoring
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (audit, error, general, slowquery for MySQL; postgresql for PostgreSQL)"
  type        = list(string)
  default     = []
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights is enabled"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Amount of time in days to retain Performance Insights data (7, 731 [2 years], or a multiple of 31)"
  type        = number
  default     = 7

  validation {
    condition     = var.performance_insights_retention_period == 7 || var.performance_insights_retention_period == 731 || (var.performance_insights_retention_period % 31 == 0)
    error_message = "Performance Insights retention period must be 7, 731, or a multiple of 31."
  }
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = string
  default     = null
}

# Authentication
variable "iam_database_authentication_enabled" {
  description = "Specifies whether IAM Database authentication is enabled"
  type        = bool
  default     = true
}

# Parameter Groups
variable "cluster_parameters" {
  description = "List of cluster parameter group parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "instance_parameters" {
  description = "List of instance parameter group parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "db_cluster_parameter_group_family" {
  description = "The family of the DB cluster parameter group (e.g., aurora-mysql8.0, aurora-postgresql14)"
  type        = string
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment must be specified."
  }
}

variable "owner" {
  description = "Owner or team responsible for the resource"
  type        = string

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner must be specified."
  }
}

# Additional Configuration
variable "apply_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately or during the next maintenance window"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the cluster during the maintenance window"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Copy all cluster tags to snapshots"
  type        = bool
  default     = true
}

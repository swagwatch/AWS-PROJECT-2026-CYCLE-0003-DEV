# RDS Aurora Module Implementation
# This module instantiates the RDS Aurora cluster for the dev environment

module "rds_aurora" {
  source = "../../modules/rds_aurora"

  # Cluster Identification
  cluster_identifier = var.cluster_identifier

  # Engine Configuration
  engine                            = var.engine
  engine_version                    = var.engine_version
  engine_mode                       = var.engine_mode
  db_cluster_parameter_group_family = var.db_cluster_parameter_group_family

  # Instance Configuration
  instance_class = var.instance_class
  instance_count = var.instance_count

  # Database Configuration
  database_name               = var.database_name
  master_username             = var.master_username
  master_password             = var.master_password
  manage_master_user_password = var.manage_master_user_password

  # Networking
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible

  # Backup & Recovery
  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = var.preferred_backup_window
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.final_snapshot_identifier

  # Encryption
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # High Availability
  deletion_protection          = var.deletion_protection
  preferred_maintenance_window = var.preferred_maintenance_window

  # Monitoring
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_role_arn

  # Authentication
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Parameter Groups
  cluster_parameters  = var.cluster_parameters
  instance_parameters = var.instance_parameters

  # Tags
  tags        = var.tags
  environment = var.environment
  owner       = var.owner

  # Additional Configuration
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  copy_tags_to_snapshot      = var.copy_tags_to_snapshot
}

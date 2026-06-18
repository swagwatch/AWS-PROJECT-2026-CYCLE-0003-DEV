# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${local.cluster_identifier_normalized}-subnet-group"
  subnet_ids  = var.subnet_ids
  description = "Subnet group for ${var.cluster_identifier} Aurora cluster"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier_normalized}-subnet-group"
    }
  )
}

# Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "this" {
  count = length(var.cluster_parameters) > 0 ? 1 : 0

  name        = "${local.cluster_identifier_normalized}-cluster-params"
  family      = var.db_cluster_parameter_group_family
  description = "Cluster parameter group for ${var.cluster_identifier} Aurora cluster"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier_normalized}-cluster-params"
    }
  )
}

# Instance Parameter Group
resource "aws_db_parameter_group" "this" {
  count = length(var.instance_parameters) > 0 ? 1 : 0

  name        = "${local.cluster_identifier_normalized}-instance-params"
  family      = var.db_cluster_parameter_group_family
  description = "Instance parameter group for ${var.cluster_identifier} Aurora cluster"

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier_normalized}-instance-params"
    }
  )
}

# IAM Role for Enhanced Monitoring (created only if needed)
resource "aws_iam_role" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  name = "${local.cluster_identifier_normalized}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier_normalized}-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = local.create_monitoring_role ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.cluster_identifier_normalized
  engine             = var.engine
  engine_version     = var.engine_version
  engine_mode        = var.engine_mode

  # Database Configuration
  database_name   = var.database_name
  master_username = var.master_username
  master_password = local.use_master_password ? var.master_password : null

  # Managed password (AWS Secrets Manager)
  manage_master_user_password = local.use_managed_password

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  # Backup Configuration
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : local.final_snapshot_identifier
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

  # Encryption
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # High Availability & Protection
  deletion_protection = var.deletion_protection

  # Monitoring & Logging
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Parameter Groups
  db_cluster_parameter_group_name = length(var.cluster_parameters) > 0 ? aws_rds_cluster_parameter_group.this[0].name : null

  # Maintenance
  apply_immediately = var.apply_immediately

  tags = merge(
    local.common_tags,
    {
      Name = local.cluster_identifier_normalized
    }
  )

  lifecycle {
    ignore_changes = [
      master_password,
      final_snapshot_identifier
    ]
  }
}

# RDS Aurora Cluster Instances
resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${local.cluster_identifier_normalized}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version     = var.engine_version

  # Network Configuration
  publicly_accessible = var.publicly_accessible

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = local.enable_enhanced_monitoring ? (
    local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn
  ) : null

  # Parameter Group
  db_parameter_group_name = length(var.instance_parameters) > 0 ? aws_db_parameter_group.this[0].name : null

  # Maintenance
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier_normalized}-${count.index + 1}"
    }
  )
}

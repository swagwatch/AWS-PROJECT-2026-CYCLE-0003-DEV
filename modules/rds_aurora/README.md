# AWS RDS Aurora Terraform Module

Terraform module for deploying AWS RDS Aurora database clusters with security best practices, high availability, and comprehensive monitoring.

## Description

This module provides a production-ready AWS RDS Aurora cluster implementation supporting both MySQL-compatible and PostgreSQL-compatible engines. It includes built-in security features (encryption, IAM authentication), automated backups, multi-AZ deployment, and integrated monitoring through Performance Insights and CloudWatch.

## Features

- **Multi-Engine Support**: Aurora MySQL and Aurora PostgreSQL compatibility
- **Multi-AZ High Availability**: Automated instance distribution across availability zones
- **Security by Default**: Encryption at rest/in-transit, IAM authentication, deletion protection
- **Automated Backups**: Configurable retention (7-35 days) with point-in-time recovery
- **Comprehensive Monitoring**: Performance Insights, Enhanced Monitoring, CloudWatch Logs
- **Flexible Parameter Groups**: Custom cluster and instance parameter configurations
- **Network Security**: Private subnet placement, security group integration
- **Automatic Password Management**: AWS Secrets Manager integration for master password
- **IAM Role Auto-Creation**: Automatic enhanced monitoring IAM role creation

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |

## Usage

### Basic Aurora MySQL Cluster

```hcl
module "aurora_mysql" {
  source = "../../modules/rds_aurora"

  cluster_identifier = "my-aurora-mysql"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.04.0"

  db_cluster_parameter_group_family = "aurora-mysql8.0"

  instance_class = "db.r5.large"
  instance_count = 2

  database_name   = "myapp"
  master_username = "admin"
  manage_master_user_password = true

  subnet_ids             = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
  vpc_security_group_ids = ["sg-xxx"]

  storage_encrypted   = true
  deletion_protection = true

  backup_retention_period = 7

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  performance_insights_enabled    = true
  monitoring_interval             = 60

  iam_database_authentication_enabled = true

  tags = {
    Application = "MyApp"
  }
  environment = "production"
  owner       = "platform-team"
}
```

### Aurora PostgreSQL Cluster

```hcl
module "aurora_postgresql" {
  source = "../../modules/rds_aurora"

  cluster_identifier = "my-aurora-postgresql"
  engine             = "aurora-postgresql"
  engine_version     = "15.3"

  db_cluster_parameter_group_family = "aurora-postgresql15"

  instance_class = "db.r5.xlarge"
  instance_count = 3

  database_name   = "mydb"
  master_username = "postgres"
  master_password = var.db_password  # Or use manage_master_user_password = true

  subnet_ids             = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
  vpc_security_group_ids = ["sg-xxx"]

  storage_encrypted   = true
  kms_key_id          = aws_kms_key.aurora.arn
  deletion_protection = true

  backup_retention_period      = 14
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]
  performance_insights_enabled    = true
  monitoring_interval             = 60

  tags = {
    Application = "PostgresApp"
  }
  environment = "production"
  owner       = "data-team"
}
```

### With Custom Parameter Groups

```hcl
module "aurora_custom_params" {
  source = "../../modules/rds_aurora"

  cluster_identifier = "aurora-custom"
  engine             = "aurora-mysql"
  engine_version     = "8.0.mysql_aurora.3.04.0"

  db_cluster_parameter_group_family = "aurora-mysql8.0"

  # Custom cluster parameters
  cluster_parameters = [
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "max_connections"
      value = "1000"
    }
  ]

  # Custom instance parameters
  instance_parameters = [
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "long_query_time"
      value = "2"
    }
  ]

  instance_class = "db.r5.large"
  instance_count = 2

  database_name               = "mydb"
  master_username             = "admin"
  manage_master_user_password = true

  subnet_ids             = ["subnet-xxx", "subnet-yyy"]
  vpc_security_group_ids = ["sg-xxx"]

  storage_encrypted   = true
  deletion_protection = true

  backup_retention_period = 7

  tags = {}
  environment = "production"
  owner       = "platform-team"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_identifier | The cluster identifier for the RDS Aurora cluster | `string` | n/a | yes |
| engine | The database engine to use (aurora-mysql or aurora-postgresql) | `string` | `"aurora-mysql"` | no |
| engine_version | The engine version to use | `string` | n/a | yes |
| engine_mode | The database engine mode (provisioned or serverless) | `string` | `"provisioned"` | no |
| instance_class | The instance class to use for Aurora instances | `string` | `"db.t3.medium"` | no |
| instance_count | Number of Aurora instances to create in the cluster | `number` | `2` | no |
| database_name | Name for an automatically created database on cluster creation | `string` | `null` | no |
| master_username | Username for the master DB user | `string` | n/a | yes |
| master_password | Password for the master DB user (use AWS Secrets Manager in production) | `string` (sensitive) | `null` | no |
| manage_master_user_password | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `false` | no |
| subnet_ids | List of subnet IDs for the DB subnet group (must span at least 2 AZs) | `list(string)` | n/a | yes |
| vpc_security_group_ids | List of VPC security group IDs to associate with the cluster | `list(string)` | n/a | yes |
| publicly_accessible | Whether the instances are publicly accessible | `bool` | `false` | no |
| backup_retention_period | The days to retain backups for (1-35 days) | `number` | `7` | no |
| preferred_backup_window | The daily time range during which automated backups are created | `string` | `null` | no |
| skip_final_snapshot | Determines whether a final DB snapshot is created before deletion | `bool` | `false` | no |
| final_snapshot_identifier | The name of the final snapshot when the cluster is deleted | `string` | `null` | no |
| storage_encrypted | Specifies whether the DB cluster is encrypted | `bool` | `true` | no |
| kms_key_id | The ARN for the KMS encryption key (if storage_encrypted is true) | `string` | `null` | no |
| deletion_protection | If true, the DB cluster cannot be deleted | `bool` | `true` | no |
| preferred_maintenance_window | The weekly time range during which system maintenance can occur | `string` | `null` | no |
| enabled_cloudwatch_logs_exports | List of log types to export to CloudWatch | `list(string)` | `[]` | no |
| performance_insights_enabled | Specifies whether Performance Insights is enabled | `bool` | `true` | no |
| performance_insights_retention_period | Amount of time in days to retain Performance Insights data | `number` | `7` | no |
| performance_insights_kms_key_id | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| monitoring_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected | `number` | `60` | no |
| monitoring_role_arn | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `string` | `null` | no |
| iam_database_authentication_enabled | Specifies whether IAM Database authentication is enabled | `bool` | `true` | no |
| cluster_parameters | List of cluster parameter group parameters to apply | `list(object({name=string, value=string}))` | `[]` | no |
| instance_parameters | List of instance parameter group parameters to apply | `list(object({name=string, value=string}))` | `[]` | no |
| db_cluster_parameter_group_family | The family of the DB cluster parameter group | `string` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| owner | Owner or team responsible for the resource | `string` | n/a | yes |
| apply_immediately | Specifies whether any cluster modifications are applied immediately | `bool` | `false` | no |
| auto_minor_version_upgrade | Indicates that minor engine upgrades will be applied automatically | `bool` | `true` | no |
| copy_tags_to_snapshot | Copy all cluster tags to snapshots | `bool` | `true` | no |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| cluster_id | The ID of the RDS Aurora cluster | `string` |
| cluster_arn | The ARN of the RDS Aurora cluster | `string` |
| cluster_endpoint | The cluster endpoint for write operations | `string` |
| cluster_reader_endpoint | The cluster reader endpoint for read operations | `string` |
| cluster_port | The port on which the DB accepts connections | `number` |
| cluster_resource_id | The Resource ID of the cluster | `string` |
| cluster_hosted_zone_id | The Route53 Hosted Zone ID of the cluster endpoint | `string` |
| instance_ids | List of RDS Aurora instance IDs | `list(string)` |
| instance_endpoints | List of RDS Aurora instance endpoints | `list(string)` |
| instance_arns | List of RDS Aurora instance ARNs | `list(string)` |
| database_name | The name of the default database | `string` |
| master_username | The master username for the database (sensitive) | `string` |
| security_group_ids | The VPC security group IDs associated with the cluster | `list(string)` |
| subnet_group_name | The name of the DB subnet group | `string` |
| subnet_group_arn | The ARN of the DB subnet group | `string` |
| cloudwatch_log_groups | List of CloudWatch log groups for exported logs | `list(string)` |
| monitoring_role_arn | The ARN of the monitoring IAM role (if created) | `string` |
| cluster_parameter_group_name | The name of the cluster parameter group | `string` |
| instance_parameter_group_name | The name of the instance parameter group | `string` |
| master_user_secret_arn | The ARN of the master user secret (when manage_master_user_password is true) (sensitive) | `string` |

## Aurora-Specific Considerations

### Engine Options

- **Aurora MySQL**: Compatible with MySQL 5.7 and 8.0
  - Engine: `aurora-mysql`
  - Engine versions: `5.7.mysql_aurora.2.x.x`, `8.0.mysql_aurora.3.x.x`
  - Parameter family: `aurora-mysql5.7`, `aurora-mysql8.0`
  - CloudWatch logs: `["audit", "error", "general", "slowquery"]`

- **Aurora PostgreSQL**: Compatible with PostgreSQL 11, 12, 13, 14, 15
  - Engine: `aurora-postgresql`
  - Engine versions: `11.x`, `12.x`, `13.x`, `14.x`, `15.x`
  - Parameter family: `aurora-postgresql11`, `aurora-postgresql12`, `aurora-postgresql13`, `aurora-postgresql14`, `aurora-postgresql15`
  - CloudWatch logs: `["postgresql"]`

### Instance Classes

- **Burstable (db.t3.*, db.t4g.*)**: Development and testing
  - Lower cost
  - Burstable CPU performance
  - Not recommended for production

- **Memory Optimized (db.r5.*, db.r6g.*, db.r6i.*)**: Production workloads
  - High memory-to-CPU ratio
  - Best for database workloads
  - Recommended for production

- **General Purpose (db.m5.*, db.m6g.*)**: Balanced workloads
  - Balanced compute, memory, and network resources

### Storage

- Aurora automatically manages storage
- Storage scales automatically from 10GB to 128TB
- Storage is allocated in 10GB increments
- No need to provision storage size

### Networking

- Subnet group must include subnets in at least 2 availability zones
- Use private subnets only (never public)
- Security groups should restrict access to application layers only
- Consider using VPC endpoints for AWS services

## Security Best Practices

1. **Never set `publicly_accessible = true`** for production databases
2. **Always enable `storage_encrypted = true`** and provide `kms_key_id` for encryption key control
3. **Use restrictive security groups** allowing only necessary access
4. **Enable `iam_database_authentication_enabled`** and use IAM database authentication over traditional passwords where possible
5. **Rotate credentials regularly** (managed via AWS Secrets Manager rotation when using `manage_master_user_password = true`)
6. **Use AWS Secrets Manager** for password management by setting `manage_master_user_password = true`
7. **Enable deletion protection** (`deletion_protection = true`) for production clusters
8. **Configure appropriate backup retention** (at least 7 days, 14-30 days for production)

## High Availability Considerations

- **Minimum 2 instances** across different AZs for high availability
- **Subnet group must span at least 2 AZs** (AWS requirement)
- **Consider 3+ instances** for read-heavy workloads to distribute read traffic
- **Set appropriate `preferred_maintenance_window`** to minimize impact
- **Use reader endpoint** for read operations to distribute load across read replicas
- **Enable automated backups** with sufficient retention for disaster recovery

## Monitoring and Alerting

This module enables Performance Insights and CloudWatch logs, but CloudWatch alarms for critical metrics should be configured separately:

- **CPU Utilization**: Alert on sustained high CPU usage
- **Database Connections**: Alert on connection pool exhaustion
- **Replica Lag**: Alert on replication delays (if applicable)
- **Storage**: Monitor available storage (though Aurora auto-scales)
- **Failed Connections**: Alert on authentication failures

Consider creating companion CloudWatch alarms or using a separate monitoring module.

## Examples

See the `environments/dev/services/rds_aurora/` directory for a complete working example.

## Authors

Generated with Claude Code

## License

[Add your license here]

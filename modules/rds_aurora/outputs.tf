# Cluster Information
output "cluster_id" {
  description = "The ID of the RDS Aurora cluster"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the RDS Aurora cluster"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The cluster endpoint for write operations"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint for read operations"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "The port on which the DB accepts connections"
  value       = aws_rds_cluster.this.port
}

output "cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "cluster_hosted_zone_id" {
  description = "The Route53 Hosted Zone ID of the cluster endpoint"
  value       = aws_rds_cluster.this.hosted_zone_id
}

# Instance Information
output "instance_ids" {
  description = "List of RDS Aurora instance IDs"
  value       = aws_rds_cluster_instance.this[*].id
}

output "instance_endpoints" {
  description = "List of RDS Aurora instance endpoints"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "instance_arns" {
  description = "List of RDS Aurora instance ARNs"
  value       = aws_rds_cluster_instance.this[*].arn
}

# Database Information
output "database_name" {
  description = "The name of the default database"
  value       = aws_rds_cluster.this.database_name
}

output "master_username" {
  description = "The master username for the database"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

# Security
output "security_group_ids" {
  description = "The VPC security group IDs associated with the cluster"
  value       = aws_rds_cluster.this.vpc_security_group_ids
}

output "subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "subnet_group_arn" {
  description = "The ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

# Monitoring
output "cloudwatch_log_groups" {
  description = "List of CloudWatch log groups for exported logs"
  value       = aws_rds_cluster.this.enabled_cloudwatch_logs_exports
}

output "monitoring_role_arn" {
  description = "The ARN of the monitoring IAM role (if created)"
  value       = local.create_monitoring_role ? aws_iam_role.monitoring[0].arn : var.monitoring_role_arn
}

# Parameter Groups
output "cluster_parameter_group_name" {
  description = "The name of the cluster parameter group"
  value       = length(var.cluster_parameters) > 0 ? aws_rds_cluster_parameter_group.this[0].name : null
}

output "instance_parameter_group_name" {
  description = "The name of the instance parameter group"
  value       = length(var.instance_parameters) > 0 ? aws_db_parameter_group.this[0].name : null
}

# Master User Secret (if using managed password)
output "master_user_secret_arn" {
  description = "The ARN of the master user secret (when manage_master_user_password is true)"
  value       = local.use_managed_password ? aws_rds_cluster.this.master_user_secret[0].secret_arn : null
  sensitive   = true
}

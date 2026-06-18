# Cluster Endpoints
output "cluster_endpoint" {
  description = "The cluster endpoint for write operations"
  value       = module.rds_aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "The cluster reader endpoint for read operations"
  value       = module.rds_aurora.cluster_reader_endpoint
}

output "cluster_port" {
  description = "The port on which the DB accepts connections"
  value       = module.rds_aurora.cluster_port
}

# Cluster Information
output "cluster_id" {
  description = "The ID of the RDS Aurora cluster"
  value       = module.rds_aurora.cluster_id
}

output "cluster_arn" {
  description = "The ARN of the RDS Aurora cluster"
  value       = module.rds_aurora.cluster_arn
}

output "cluster_resource_id" {
  description = "The Resource ID of the cluster"
  value       = module.rds_aurora.cluster_resource_id
}

# Database Information
output "database_name" {
  description = "The name of the default database"
  value       = module.rds_aurora.database_name
}

output "master_username" {
  description = "The master username for the database"
  value       = module.rds_aurora.master_username
  sensitive   = true
}

# Instance Information
output "instance_ids" {
  description = "List of RDS Aurora instance IDs"
  value       = module.rds_aurora.instance_ids
}

output "instance_endpoints" {
  description = "List of RDS Aurora instance endpoints"
  value       = module.rds_aurora.instance_endpoints
}

# Security
output "security_group_ids" {
  description = "The VPC security group IDs associated with the cluster"
  value       = module.rds_aurora.security_group_ids
}

output "subnet_group_name" {
  description = "The name of the DB subnet group"
  value       = module.rds_aurora.subnet_group_name
}

output "secret_arn" {
  description = "ARN of the secret."
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  description = "ID of the secret."
  value       = aws_secretsmanager_secret.this.id
}

output "secret_name" {
  description = "Name of the secret."
  value       = aws_secretsmanager_secret.this.name
}

output "version_id" {
  description = "Version ID of the current secret version."
  value       = try(aws_secretsmanager_secret_version.this[0].version_id, null)
}

output "rotation_enabled" {
  description = "Whether rotation is enabled for this secret."
  value       = var.rotation_enabled
}

output "replica_status" {
  description = "Map of replica regions and their status."
  value = {
    for replica in aws_secretsmanager_secret.this.replica :
    replica.region => {
      status         = replica.status
      status_message = replica.status_message
    }
  }
}

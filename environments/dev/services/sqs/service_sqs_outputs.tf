output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = module.sqs.queue_id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = module.sqs.queue_arn
}

output "queue_url" {
  description = "The URL for the created Amazon SQS queue"
  value       = module.sqs.queue_url
}

output "queue_name" {
  description = "The name of the queue"
  value       = module.sqs.queue_name
}

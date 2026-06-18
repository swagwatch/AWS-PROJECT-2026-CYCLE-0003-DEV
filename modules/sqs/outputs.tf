output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.this.url
}

output "queue_name" {
  description = "The name of the queue"
  value       = aws_sqs_queue.this.name
}

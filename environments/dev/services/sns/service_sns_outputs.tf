output "topic_arn" {
  description = "The ARN of the SNS topic"
  value       = module.sns_topic.topic_arn
}

output "topic_id" {
  description = "The ID of the SNS topic"
  value       = module.sns_topic.topic_id
}

output "topic_name" {
  description = "The name of the SNS topic"
  value       = module.sns_topic.topic_name
}

output "subscription_arns" {
  description = "The ARNs of the SNS topic subscriptions"
  value       = module.sns_topic.subscription_arns
}

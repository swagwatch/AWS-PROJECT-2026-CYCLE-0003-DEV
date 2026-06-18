output "cloudfront_distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = module.cloudfront_distribution.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "The ARN for the CloudFront distribution"
  value       = module.cloudfront_distribution.distribution_arn
}

output "cloudfront_distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = module.cloudfront_distribution.distribution_domain_name
}

output "cloudfront_distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = module.cloudfront_distribution.distribution_hosted_zone_id
}

output "cloudfront_distribution_status" {
  description = "The current status of the distribution"
  value       = module.cloudfront_distribution.distribution_status
}

output "cloudfront_origin_access_control_id" {
  description = "The ID of the Origin Access Control (if created)"
  value       = module.cloudfront_distribution.origin_access_control_id
}

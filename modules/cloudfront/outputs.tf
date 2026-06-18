output "distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN (Amazon Resource Name) for the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name corresponding to the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID that can be used to route an Alias Resource Record Set to"
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_status" {
  description = "The current status of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.status
}

output "distribution_etag" {
  description = "The current version of the distribution's information"
  value       = aws_cloudfront_distribution.this.etag
}

output "origin_access_control_id" {
  description = "The ID of the Origin Access Control (if created)"
  value       = var.create_origin_access_control ? aws_cloudfront_origin_access_control.this[0].id : null
}

output "origin_access_control_etag" {
  description = "The current version of the Origin Access Control (if created)"
  value       = var.create_origin_access_control ? aws_cloudfront_origin_access_control.this[0].etag : null
}

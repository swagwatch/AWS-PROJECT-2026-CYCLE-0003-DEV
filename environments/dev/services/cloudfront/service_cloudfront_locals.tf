# Local values for dev CloudFront service
locals {
  service_name = "cloudfront"

  # Merge environment-specific tags
  service_tags = {
    Service = local.service_name
  }
}

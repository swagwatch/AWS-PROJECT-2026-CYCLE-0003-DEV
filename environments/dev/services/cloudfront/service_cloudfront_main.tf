module "cloudfront_distribution" {
  source = "../../modules/cloudfront"

  # Distribution configuration
  enabled             = var.enabled
  comment             = var.comment
  aliases             = var.aliases
  default_root_object = var.default_root_object
  price_class         = var.price_class
  http_version        = var.http_version
  is_ipv6_enabled     = var.is_ipv6_enabled
  web_acl_id          = var.web_acl_id
  wait_for_deployment = var.wait_for_deployment
  retain_on_delete    = var.retain_on_delete

  # Origins
  origins                      = var.origins
  create_origin_access_control = var.create_origin_access_control
  origin_access_control_name   = var.origin_access_control_name

  # Cache behaviors
  default_cache_behavior  = var.default_cache_behavior
  ordered_cache_behaviors = var.ordered_cache_behaviors

  # SSL/TLS
  viewer_certificate = var.viewer_certificate

  # Geo-restriction
  geo_restriction = var.geo_restriction

  # Logging
  logging_config = var.logging_config

  # Custom error responses
  custom_error_responses = var.custom_error_responses

  # Tags
  environment = var.environment
  owner       = var.owner
  project     = var.project
  tags        = var.tags
}

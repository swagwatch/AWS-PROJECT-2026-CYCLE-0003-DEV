variable "enabled" {
  description = "Whether the CloudFront distribution is enabled"
  type        = bool
}

variable "comment" {
  description = "Comments about the distribution"
  type        = string
}

variable "aliases" {
  description = "Extra CNAMEs for this distribution"
  type        = list(string)
}

variable "default_root_object" {
  description = "The object to return when root URL is requested"
  type        = string
}

variable "price_class" {
  description = "The price class for this distribution"
  type        = string
}

variable "http_version" {
  description = "The maximum HTTP version to support"
  type        = string
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled"
  type        = bool
}

variable "web_acl_id" {
  description = "The ARN of the AWS WAF web ACL"
  type        = string
}

variable "origins" {
  description = "One or more origins for this distribution"
  type = list(object({
    domain_name         = string
    origin_id           = string
    origin_path         = optional(string, "")
    connection_attempts = optional(number, 3)
    connection_timeout  = optional(number, 10)
    custom_origin_config = optional(object({
      http_port                = optional(number, 80)
      https_port               = optional(number, 443)
      origin_protocol_policy   = string
      origin_ssl_protocols     = list(string)
      origin_keepalive_timeout = optional(number, 5)
      origin_read_timeout      = optional(number, 30)
    }))
    s3_origin_config = optional(object({
      origin_access_identity = optional(string, "")
    }))
    custom_header = optional(list(object({
      name  = string
      value = string
    })), [])
    origin_shield = optional(object({
      enabled              = bool
      origin_shield_region = string
    }))
  }))
}

variable "create_origin_access_control" {
  description = "Whether to create an Origin Access Control"
  type        = bool
}

variable "origin_access_control_name" {
  description = "Name for the Origin Access Control"
  type        = string
}

variable "default_cache_behavior" {
  description = "The default cache behavior for this distribution"
  type = object({
    target_origin_id           = string
    viewer_protocol_policy     = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    compress                   = optional(bool, true)
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 3600)
    max_ttl                    = optional(number, 86400)
    forwarded_values = optional(object({
      query_string = bool
      headers      = optional(list(string), [])
      cookies = object({
        forward = string
      })
    }))
  })
}

variable "ordered_cache_behaviors" {
  description = "An ordered list of cache behaviors"
  type = list(object({
    path_pattern               = string
    target_origin_id           = string
    viewer_protocol_policy     = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    compress                   = optional(bool, true)
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 3600)
    max_ttl                    = optional(number, 86400)
    forwarded_values = optional(object({
      query_string = bool
      headers      = optional(list(string), [])
      cookies = object({
        forward = string
      })
    }))
  }))
}

variable "viewer_certificate" {
  description = "The SSL configuration for this distribution"
  type = object({
    cloudfront_default_certificate = optional(bool, false)
    acm_certificate_arn            = optional(string)
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
    ssl_support_method             = optional(string, "sni-only")
  })
}

variable "geo_restriction" {
  description = "The restriction configuration for this distribution"
  type = object({
    restriction_type = string
    locations        = optional(list(string), [])
  })
}

variable "logging_config" {
  description = "The logging configuration for this distribution"
  type = object({
    enabled         = bool
    bucket          = optional(string, "")
    prefix          = optional(string, "")
    include_cookies = optional(bool, false)
  })
}

variable "custom_error_responses" {
  description = "Custom error response configuration"
  type = list(object({
    error_code         = number
    response_code      = optional(number)
    response_page_path = optional(string)
  }))
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for this resource"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
}

variable "wait_for_deployment" {
  description = "Wait for distribution status to change to Deployed"
  type        = bool
}

variable "retain_on_delete" {
  description = "Disables the distribution instead of deleting it"
  type        = bool
}

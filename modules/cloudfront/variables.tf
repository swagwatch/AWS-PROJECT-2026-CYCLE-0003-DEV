variable "enabled" {
  description = "Whether the CloudFront distribution is enabled to accept end user requests"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Any comments you want to include about the distribution"
  type        = string
  default     = "Managed by Terraform"
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names) for this distribution"
  type        = list(string)
  default     = []
}

variable "default_root_object" {
  description = "The object that you want CloudFront to return when an end user requests the root URL"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100"
  }
}

variable "http_version" {
  description = "The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3"
  type        = string
  default     = "http2"

  validation {
    condition     = contains(["http1.1", "http2", "http2and3", "http3"], var.http_version)
    error_message = "HTTP version must be one of: http1.1, http2, http2and3, http3"
  }
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "The ARN of the AWS WAF web ACL to associate with this distribution"
  type        = string
  default     = ""
}

# Origins configuration
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

  validation {
    condition     = length(var.origins) > 0
    error_message = "At least one origin must be specified"
  }
}

variable "create_origin_access_control" {
  description = "Whether to create an Origin Access Control for S3 origins"
  type        = bool
  default     = false
}

variable "origin_access_control_name" {
  description = "Name for the Origin Access Control (if created)"
  type        = string
  default     = ""
}

variable "origin_access_control_description" {
  description = "Description for the Origin Access Control (if created)"
  type        = string
  default     = "Origin Access Control for CloudFront"
}

variable "origin_access_control_signing_behavior" {
  description = "Signing behavior for OAC. Valid values: always, never, no-override"
  type        = string
  default     = "always"

  validation {
    condition     = contains(["always", "never", "no-override"], var.origin_access_control_signing_behavior)
    error_message = "Signing behavior must be one of: always, never, no-override"
  }
}

variable "origin_access_control_origin_type" {
  description = "Origin type for OAC. Valid values: s3, mediastore"
  type        = string
  default     = "s3"

  validation {
    condition     = contains(["s3", "mediastore"], var.origin_access_control_origin_type)
    error_message = "Origin type must be one of: s3, mediastore"
  }
}

# Default cache behavior configuration
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
    realtime_log_config_arn    = optional(string)
    smooth_streaming           = optional(bool, false)
    trusted_signers            = optional(list(string), [])
    trusted_key_groups         = optional(list(string), [])
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 3600)
    max_ttl                    = optional(number, 86400)
    forwarded_values = optional(object({
      query_string            = bool
      query_string_cache_keys = optional(list(string), [])
      headers                 = optional(list(string), [])
      cookies = object({
        forward           = string
        whitelisted_names = optional(list(string), [])
      })
    }))
    lambda_function_association = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_association = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  })

  validation {
    condition     = contains(["allow-all", "https-only", "redirect-to-https"], var.default_cache_behavior.viewer_protocol_policy)
    error_message = "Viewer protocol policy must be one of: allow-all, https-only, redirect-to-https"
  }
}

# Ordered cache behaviors configuration
variable "ordered_cache_behaviors" {
  description = "An ordered list of cache behaviors for this distribution"
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
    realtime_log_config_arn    = optional(string)
    smooth_streaming           = optional(bool, false)
    trusted_signers            = optional(list(string), [])
    trusted_key_groups         = optional(list(string), [])
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 3600)
    max_ttl                    = optional(number, 86400)
    forwarded_values = optional(object({
      query_string            = bool
      query_string_cache_keys = optional(list(string), [])
      headers                 = optional(list(string), [])
      cookies = object({
        forward           = string
        whitelisted_names = optional(list(string), [])
      })
    }))
    lambda_function_association = optional(list(object({
      event_type   = string
      lambda_arn   = string
      include_body = optional(bool, false)
    })), [])
    function_association = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
  default = []
}

# SSL/TLS configuration
variable "viewer_certificate" {
  description = "The SSL configuration for this distribution"
  type = object({
    cloudfront_default_certificate = optional(bool, false)
    acm_certificate_arn            = optional(string)
    iam_certificate_id             = optional(string)
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
    ssl_support_method             = optional(string, "sni-only")
  })
  default = {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  validation {
    condition = contains([
      "SSLv3", "TLSv1", "TLSv1_2016", "TLSv1.1_2016", "TLSv1.2_2018",
      "TLSv1.2_2019", "TLSv1.2_2021", "TLSv1.3_2021"
    ], var.viewer_certificate.minimum_protocol_version)
    error_message = "Minimum protocol version must be a valid TLS version"
  }
}

# Geo-restriction configuration
variable "geo_restriction" {
  description = "The restriction configuration for this distribution"
  type = object({
    restriction_type = string
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
    locations        = []
  }

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction.restriction_type)
    error_message = "Restriction type must be one of: none, whitelist, blacklist"
  }
}

# Logging configuration
variable "logging_config" {
  description = "The logging configuration for this distribution"
  type = object({
    enabled         = bool
    bucket          = optional(string, "")
    prefix          = optional(string, "")
    include_cookies = optional(bool, false)
  })
  default = {
    enabled = false
  }
}

# Custom error responses
variable "custom_error_responses" {
  description = "Custom error response configuration"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 10)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Required for tagging."
  type        = string
}

variable "owner" {
  description = "Owner or team responsible for this resource. Required for tagging."
  type        = string
}

variable "project" {
  description = "Project name. Optional for tagging."
  type        = string
  default     = ""
}

# Wait for deployment
variable "wait_for_deployment" {
  description = "If enabled, the resource will wait for the distribution status to change from InProgress to Deployed"
  type        = bool
  default     = true
}

variable "retain_on_delete" {
  description = "Disables the distribution instead of deleting it when destroying the resource"
  type        = bool
  default     = false
}

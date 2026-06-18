enabled      = true
comment      = "Dev CloudFront distribution for content delivery"
price_class  = "PriceClass_100"
http_version = "http2"

# Origins configuration - S3 origin example
origins = [
  {
    domain_name         = "my-dev-content-bucket.s3.us-east-1.amazonaws.com"
    origin_id           = "S3-dev-content"
    origin_path         = ""
    connection_attempts = 3
    connection_timeout  = 10
  }
]

# Create Origin Access Control for S3
create_origin_access_control = true
origin_access_control_name   = "dev-cloudfront-oac"

# Default cache behavior
default_cache_behavior = {
  target_origin_id       = "S3-dev-content"
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods        = ["GET", "HEAD", "OPTIONS"]
  cached_methods         = ["GET", "HEAD"]
  compress               = true

  forwarded_values = {
    query_string = false
    headers      = []
    cookies = {
      forward = "none"
    }
  }

  min_ttl     = 0
  default_ttl = 3600
  max_ttl     = 86400
}

# Ordered cache behaviors (optional - add path-specific behaviors here)
ordered_cache_behaviors = []

# SSL/TLS configuration
viewer_certificate = {
  cloudfront_default_certificate = true
  minimum_protocol_version       = "TLSv1.2_2021"
  ssl_support_method             = "sni-only"
}

# Geo-restriction configuration
geo_restriction = {
  restriction_type = "none"
  locations        = []
}

# Logging configuration
logging_config = {
  enabled         = true
  bucket          = "my-dev-cloudfront-logs.s3.amazonaws.com"
  prefix          = "cloudfront/dev/"
  include_cookies = false
}

# Custom error responses (optional)
custom_error_responses = [
  {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  },
  {
    error_code         = 403
    response_code      = 403
    response_page_path = "/403.html"
  }
]

# Required tags
environment = "dev"
owner       = "platform-team"
project     = "cdn-infrastructure"

# Additional tags
tags = {
  CostCenter = "engineering"
  ManagedBy  = "Terraform"
}

# WAF configuration (empty for dev, required for prod)
web_acl_id = ""

# Distribution settings
default_root_object = "index.html"
aliases             = []
is_ipv6_enabled     = true
wait_for_deployment = true
retain_on_delete    = false

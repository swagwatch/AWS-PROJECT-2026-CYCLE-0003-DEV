environment  = "dev"
project_name = "xray-demo"

tags = {
  Environment = "dev"
  Owner       = "platform-team"
  Project     = "xray-demo"
  CostCenter  = "engineering"
}

# Custom Sampling Rules
sampling_rules = [
  {
    rule_name      = "api-high-priority"
    priority       = 100
    fixed_rate     = 0.10
    reservoir_size = 5
    url_path       = "/api/*"
    host           = "*"
    http_method    = "*"
    service_name   = "*"
    service_type   = "*"
    resource_arn   = "*"
    version        = 1
    attributes     = {}
  }
]

# Default Sampling Rule Configuration
create_default_sampling_rule = true
default_sampling_rate        = 0.05
default_reservoir_size       = 1

# Encryption Configuration
encryption_enabled = true
encryption_type    = "KMS"
encryption_key_id  = null # Will use AWS managed key

# X-Ray Groups
xray_groups = [
  {
    group_name        = "errors-group"
    filter_expression = "http.status >= 500"
    insights_enabled  = false
  },
  {
    group_name        = "slow-requests"
    filter_expression = "responsetime > 5"
    insights_enabled  = false
  }
]

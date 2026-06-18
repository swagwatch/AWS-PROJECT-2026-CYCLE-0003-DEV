package terraform.aws.wafandshield

# Evaluate Terraform plan JSON (terraform show -json plan.tfplan)
# Provides:
# - deny: CRITICAL violations that must fail the pipeline
# - warn: non-blocking warnings
# - info: informational findings

# Helper: return resource changes for a given type that are created or updated
resource_changes_by_type(res_type) := array.concat(creates, updates) if {
  creates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "create")
  ]
  updates := [rc |
    rc := input.resource_changes[_]
    rc.type == res_type
    actions := rc.change.actions
    array_contains(actions, "update")
  ]
}

# Helper: get tags from after object
get_tags(after) = tags_out if {
  tags := after.tags
  tags_out := tags
} else = tags_all_out if {
  tags_all := after.tags_all
  tags_all_out := tags_all
} else = {} if {
  true
}

# Helper: check if a list contains a value
array_contains(arr, v) if {
  some i
  arr[i] == v
}

# ------------------------
# DENY Rules (Security Best Practices - CRITICAL)
# ------------------------

# DENY: WAF Web ACL must have required tags (Environment and Owner)
deny contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  tags := get_tags(rc.change.after)
  not tags.Environment
  violation := {
    "msg": "WAF Web ACL must have 'Environment' tag",
    "address": rc.address,
  }
}

deny contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  tags := get_tags(rc.change.after)
  not tags.Owner
  violation := {
    "msg": "WAF Web ACL must have 'Owner' tag",
    "address": rc.address,
  }
}

# DENY: WAF Web ACL must have logging enabled (visibility_config)
deny contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  visibility := rc.change.after.visibility_config[_]
  visibility.cloudwatch_metrics_enabled == false
  violation := {
    "msg": "WAF Web ACL must have CloudWatch metrics enabled for security monitoring",
    "address": rc.address,
  }
}

# DENY: WAF Web ACL must have sampled requests enabled for forensics
deny contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  visibility := rc.change.after.visibility_config[_]
  visibility.sampled_requests_enabled == false
  violation := {
    "msg": "WAF Web ACL must have sampled requests enabled for security forensics",
    "address": rc.address,
  }
}

# DENY: WAF Web ACL name cannot contain wildcard patterns
deny contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  name := rc.change.after.name
  contains(name, "*")
  violation := {
    "msg": "WAF Web ACL name cannot contain wildcard characters",
    "address": rc.address,
  }
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: Consider adding rate limiting rules for DDoS protection
warn contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  rules := rc.change.after.rule
  not has_rate_limit_rule(rules)
  violation := {
    "msg": "Consider adding rate limiting rules to protect against DDoS attacks",
    "address": rc.address,
  }
}

has_rate_limit_rule(rules) if {
  some rule in rules
  rule.statement[_].rate_based_statement
}

# WARN: Consider using AWS Managed Rules for common protections
warn contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  rules := rc.change.after.rule
  not has_managed_rule_group(rules)
  violation := {
    "msg": "Consider using AWS Managed Rule Groups for common vulnerability protection",
    "address": rc.address,
  }
}

has_managed_rule_group(rules) if {
  some rule in rules
  rule.statement[_].managed_rule_group_statement
}

# WARN: Consider adding geo-blocking rules for additional security
warn contains violation if {
  some rc in resource_changes_by_type("aws_wafv2_web_acl")
  rules := rc.change.after.rule
  not has_geo_match_rule(rules)
  violation := {
    "msg": "Consider adding geo-blocking rules to restrict access by geographic location",
    "address": rc.address,
  }
}

has_geo_match_rule(rules) if {
  some rule in rules
  rule.statement[_].geo_match_statement
}

# WARN: Shield Advanced is expensive - ensure it's justified
warn contains violation if {
  some rc in resource_changes_by_type("aws_shield_protection")
  tags := get_tags(rc.change.after)
  not tags.Environment == "prod"
  violation := {
    "msg": "AWS Shield Advanced is expensive and typically only justified for production environments",
    "address": rc.address,
  }
}

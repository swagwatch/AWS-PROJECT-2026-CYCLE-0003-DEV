package terraform.aws.cloudfront

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

# CRITICAL: Deny if viewer protocol policy allows unencrypted HTTP traffic
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	# Check default cache behavior
	protocol_policy := after.default_cache_behavior[_].viewer_protocol_policy
	protocol_policy == "allow-all"

	msg := {
		"msg": sprintf("CloudFront distribution '%s' allows unencrypted HTTP traffic (viewer_protocol_policy='allow-all'). Must use 'https-only' or 'redirect-to-https'.", [resource.address]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if ordered cache behaviors allow unencrypted HTTP traffic
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	some i
	behavior := after.ordered_cache_behavior[i]
	protocol_policy := behavior.viewer_protocol_policy
	protocol_policy == "allow-all"

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has ordered cache behavior with path pattern '%s' that allows unencrypted HTTP traffic. Must use 'https-only' or 'redirect-to-https'.", [resource.address, behavior.path_pattern]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if minimum TLS version is below TLSv1.2_2021
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	viewer_cert := after.viewer_certificate[_]
	min_protocol := viewer_cert.minimum_protocol_version

	# List of deprecated/insecure TLS versions
	deprecated_protocols := ["SSLv3", "TLSv1", "TLSv1_2016", "TLSv1.1_2016", "TLSv1.2_2018", "TLSv1.2_2019"]
	array_contains(deprecated_protocols, min_protocol)

	msg := {
		"msg": sprintf("CloudFront distribution '%s' uses deprecated TLS version '%s'. Minimum should be 'TLSv1.2_2021' or 'TLSv1.3_2021'.", [resource.address, min_protocol]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if required tags are missing (Environment, Owner)
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	required_tags := ["Environment", "Owner"]
	some i
	required_tag := required_tags[i]
	not tags[required_tag]

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is missing required tag '%s'.", [resource.address, required_tag]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if custom origin uses insecure HTTP-only protocol
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	some i
	origin := after.origin[i]
	custom_config := origin.custom_origin_config[_]
	protocol_policy := custom_config.origin_protocol_policy
	protocol_policy == "http-only"

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has origin '%s' using insecure 'http-only' protocol. Use 'https-only' or 'match-viewer'.", [resource.address, origin.origin_id]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if default_root_object is not set (prevents directory listing)
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	# Check if default_root_object is null or empty
	default_root := after.default_root_object
	default_root == null

	msg := {
		"msg": sprintf("CloudFront distribution '%s' does not have default_root_object set. This could expose directory listings.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	# Check if default_root_object is empty string
	default_root := after.default_root_object
	default_root == ""

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has empty default_root_object. This could expose directory listings.", [resource.address]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if logging is not enabled for production distributions
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "prod"

	# Check if logging is disabled (no logging_config block or empty array)
	not after.logging_config

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but logging is not enabled.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "production"

	# Check if logging is disabled (no logging_config block or empty array)
	not after.logging_config

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but logging is not enabled.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "prod"

	# Check if logging_config exists but is empty array
	count(after.logging_config) == 0

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but logging is not enabled.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "production"

	# Check if logging_config exists but is empty array
	count(after.logging_config) == 0

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but logging is not enabled.", [resource.address]),
		"resource": resource.address,
	}
}

# CRITICAL: Deny if WAF is not attached to production distributions
deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "prod"

	# Check if web_acl_id is null or empty
	web_acl := after.web_acl_id
	web_acl == ""

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but does not have a WAF Web ACL attached.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "production"

	# Check if web_acl_id is null or empty
	web_acl := after.web_acl_id
	web_acl == ""

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but does not have a WAF Web ACL attached.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "prod"

	# Check if web_acl_id is null
	web_acl := after.web_acl_id
	web_acl == null

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but does not have a WAF Web ACL attached.", [resource.address]),
		"resource": resource.address,
	}
}

deny contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is prod/production
	env := tags["Environment"]
	lower(env) == "production"

	# Check if web_acl_id is null
	web_acl := after.web_acl_id
	web_acl == null

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is in production environment but does not have a WAF Web ACL attached.", [resource.address]),
		"resource": resource.address,
	}
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARNING: Warn if using PriceClass_All (most expensive)
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	price_class := after.price_class
	price_class == "PriceClass_All"

	msg := {
		"msg": sprintf("CloudFront distribution '%s' uses 'PriceClass_All' which is the most expensive option. Consider 'PriceClass_200' or 'PriceClass_100' if global edge locations are not required.", [resource.address]),
		"resource": resource.address,
	}
}

# WARNING: Warn if compression is disabled in default cache behavior
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	behavior := after.default_cache_behavior[_]
	compress := behavior.compress
	compress == false

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has compression disabled in default cache behavior. Enabling compression can reduce bandwidth costs and improve performance.", [resource.address]),
		"resource": resource.address,
	}
}

# WARNING: Warn if compression is disabled in ordered cache behaviors
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	some i
	behavior := after.ordered_cache_behavior[i]
	compress := behavior.compress
	compress == false

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has compression disabled for cache behavior with path pattern '%s'. Enabling compression can reduce bandwidth costs.", [resource.address, behavior.path_pattern]),
		"resource": resource.address,
	}
}

# WARNING: Warn if not using HTTP/2 or HTTP/3
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	http_version := after.http_version
	http_version == "http1.1"

	msg := {
		"msg": sprintf("CloudFront distribution '%s' is using HTTP/1.1. Consider upgrading to 'http2' or 'http2and3' for better performance.", [resource.address]),
		"resource": resource.address,
	}
}

# WARNING: Warn if origin timeout is excessive (> 60 seconds)
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	some i
	origin := after.origin[i]
	custom_config := origin.custom_origin_config[_]
	timeout := custom_config.origin_read_timeout
	timeout > 60

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has origin '%s' with read timeout of %d seconds (> 60). High timeouts can negatively impact user experience.", [resource.address, origin.origin_id, timeout]),
		"resource": resource.address,
	}
}

# WARNING: Warn if max TTL is excessively high (> 1 year)
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after

	behavior := after.default_cache_behavior[_]
	max_ttl := behavior.max_ttl
	max_ttl > 31536000 # 1 year in seconds

	msg := {
		"msg": sprintf("CloudFront distribution '%s' has max_ttl of %d seconds (> 1 year) in default cache behavior. Consider lowering for better cache freshness.", [resource.address, max_ttl]),
		"resource": resource.address,
	}
}

# WARNING: Warn if logging is not enabled for non-production environments
warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is not prod/production
	env := tags["Environment"]
	lower(env) != "prod"
	lower(env) != "production"

	# Check if logging is disabled
	not after.logging_config

	msg := {
		"msg": sprintf("CloudFront distribution '%s' does not have logging enabled. Consider enabling logging for troubleshooting and analytics.", [resource.address]),
		"resource": resource.address,
	}
}

warn contains msg if {
	resource := resource_changes_by_type("aws_cloudfront_distribution")[_]
	after := resource.change.after
	tags := get_tags(after)

	# Check if environment is not prod/production
	env := tags["Environment"]
	lower(env) != "prod"
	lower(env) != "production"

	# Check if logging_config exists but is empty
	count(after.logging_config) == 0

	msg := {
		"msg": sprintf("CloudFront distribution '%s' does not have logging enabled. Consider enabling logging for troubleshooting and analytics.", [resource.address]),
		"resource": resource.address,
	}
}

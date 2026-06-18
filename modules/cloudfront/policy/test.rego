package terraform.aws.cloudfront

import data.terraform.aws.cloudfront

# Valid configuration test: should have no denies and possibly zero warns
test_valid_configuration_no_violations if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"price_class": "PriceClass_100",
					"http_version": "http2",
					"default_root_object": "index.html",
					"web_acl_id": "",
					"default_cache_behavior": [{
						"viewer_protocol_policy": "redirect-to-https",
						"compress": true,
						"max_ttl": 86400,
					}],
					"ordered_cache_behavior": [],
					"viewer_certificate": [{
						"cloudfront_default_certificate": true,
						"minimum_protocol_version": "TLSv1.2_2021",
					}],
					"logging_config": [{
						"bucket": "my-logs.s3.amazonaws.com",
						"prefix": "cloudfront/",
					}],
					"origin": [{
						"origin_id": "S3-my-bucket",
						"domain_name": "my-bucket.s3.amazonaws.com",
					}],
					"tags_all": {
						"Environment": "dev",
						"Owner": "platform-team",
						"ManagedBy": "Terraform",
					},
				},
			},
		}],
	}

	count(result) == 0
}

# Invalid configuration test: multiple violations expected
test_invalid_configuration_with_violations if {
	# Test configuration with multiple CRITICAL violations
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"price_class": "PriceClass_100",
					"http_version": "http1.1",
					"default_root_object": "",
					"web_acl_id": "",
					"default_cache_behavior": [{
						"viewer_protocol_policy": "allow-all",
						"compress": false,
					}],
					"ordered_cache_behavior": [],
					"viewer_certificate": [{
						"cloudfront_default_certificate": true,
						"minimum_protocol_version": "TLSv1",
					}],
					"logging_config": [],
					"origin": [{
						"origin_id": "custom-origin",
						"domain_name": "example.com",
						"custom_origin_config": [{
							"origin_protocol_policy": "http-only",
							"origin_ssl_protocols": ["TLSv1"],
						}],
					}],
					"tags_all": {
						"ManagedBy": "Terraform",
					},
				},
			},
		}],
	}

	# Should have multiple violations:
	# 1. HTTP allowed (allow-all viewer protocol)
	# 2. Deprecated TLS version (TLSv1)
	# 3. Missing required tags (Environment, Owner)
	# 4. HTTP-only origin protocol
	# 5. Empty default_root_object
	count(result) > 0

	# Verify specific violations are detected
	some violation in result
	contains(violation.msg, "allows unencrypted HTTP traffic")
}

test_invalid_configuration_missing_tags if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"default_root_object": "index.html",
					"default_cache_behavior": [{"viewer_protocol_policy": "https-only"}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {},
				},
			},
		}],
	}

	# Should have violations for missing Environment and Owner tags
	count(result) >= 2

	some violation in result
	contains(violation.msg, "missing required tag")
}

test_invalid_configuration_deprecated_tls if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"default_root_object": "index.html",
					"default_cache_behavior": [{"viewer_protocol_policy": "https-only"}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2018"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "dev",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have violation for deprecated TLS version
	count(result) > 0

	some violation in result
	contains(violation.msg, "deprecated TLS version")
}

# Edge case: Deleted resources should not trigger validations
test_delete_action_ignored if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["delete"],
				"after": null,
				"before": {
					"enabled": true,
					"default_cache_behavior": [{"viewer_protocol_policy": "allow-all"}],
					"viewer_certificate": [{"minimum_protocol_version": "SSLv3"}],
					"tags_all": {},
				},
			},
		}],
	}

	# Delete actions should be ignored by policies
	count(result) == 0
}

# Test warning rules
test_warning_price_class_all if {
	result := warn with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"price_class": "PriceClass_All",
					"http_version": "http2",
					"default_root_object": "index.html",
					"default_cache_behavior": [{
						"viewer_protocol_policy": "https-only",
						"compress": true,
					}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "dev",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have warning for PriceClass_All
	count(result) > 0

	some warning in result
	contains(warning.msg, "PriceClass_All")
}

test_warning_http_version if {
	result := warn with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"price_class": "PriceClass_100",
					"http_version": "http1.1",
					"default_root_object": "index.html",
					"default_cache_behavior": [{
						"viewer_protocol_policy": "https-only",
						"compress": true,
					}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "dev",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have warning for HTTP/1.1
	count(result) > 0

	some warning in result
	contains(warning.msg, "HTTP/1.1")
}

test_warning_compression_disabled if {
	result := warn with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"price_class": "PriceClass_100",
					"http_version": "http2",
					"default_root_object": "index.html",
					"default_cache_behavior": [{
						"viewer_protocol_policy": "https-only",
						"compress": false,
					}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "dev",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have warning for compression disabled
	count(result) > 0

	some warning in result
	contains(warning.msg, "compression disabled")
}

# Test production environment specific rules
test_production_requires_waf if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"default_root_object": "index.html",
					"web_acl_id": "",
					"default_cache_behavior": [{"viewer_protocol_policy": "https-only"}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"logging_config": [{"bucket": "logs.s3.amazonaws.com"}],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "prod",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have violation for missing WAF in production
	count(result) > 0

	some violation in result
	contains(violation.msg, "WAF Web ACL")
}

test_production_requires_logging if {
	result := deny with input as {
		"resource_changes": [{
			"type": "aws_cloudfront_distribution",
			"address": "module.cloudfront.aws_cloudfront_distribution.this",
			"change": {
				"actions": ["create"],
				"after": {
					"enabled": true,
					"default_root_object": "index.html",
					"web_acl_id": "arn:aws:wafv2:us-east-1:123456789012:global/webacl/test/a1b2c3d4",
					"default_cache_behavior": [{"viewer_protocol_policy": "https-only"}],
					"viewer_certificate": [{"minimum_protocol_version": "TLSv1.2_2021"}],
					"logging_config": [],
					"origin": [{"origin_id": "test"}],
					"tags_all": {
						"Environment": "production",
						"Owner": "team",
					},
				},
			},
		}],
	}

	# Should have violation for missing logging in production
	count(result) > 0

	some violation in result
	contains(violation.msg, "logging is not enabled")
}

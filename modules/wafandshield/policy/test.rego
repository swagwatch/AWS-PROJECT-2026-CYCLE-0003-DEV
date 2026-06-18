package terraform.aws.wafandshield

import data.terraform.aws.wafandshield

# Helper to count items
count(arr) = n if {
  n := sum([1 | arr[_]])
}

# Valid configuration test: should have no denies and possibly some warns
test_valid_waf_configuration if {
  result := wafandshield.deny with input as {
    "resource_changes": [
      {
        "address": "aws_wafv2_web_acl.test",
        "type": "aws_wafv2_web_acl",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "test-web-acl",
            "scope": "REGIONAL",
            "description": "Test WAF Web ACL",
            "default_action": [{"allow": {}}],
            "rule": [],
            "visibility_config": [
              {
                "cloudwatch_metrics_enabled": true,
                "metric_name": "test_web_acl",
                "sampled_requests_enabled": true,
              },
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "ManagedBy": "Terraform",
            },
          },
        },
      },
    ],
  }
  count(result) == 0
}

# Invalid configuration test: multiple violations expected (missing tags, logging disabled)
test_invalid_waf_configuration if {
  result := wafandshield.deny with input as {
    "resource_changes": [
      {
        "address": "aws_wafv2_web_acl.test",
        "type": "aws_wafv2_web_acl",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "test-*-acl",
            "scope": "REGIONAL",
            "description": "Invalid WAF Web ACL",
            "default_action": [{"allow": {}}],
            "rule": [],
            "visibility_config": [
              {
                "cloudwatch_metrics_enabled": false,
                "metric_name": "test_web_acl",
                "sampled_requests_enabled": false,
              },
            ],
            "tags": {},
          },
        },
      },
    ],
  }
  count(result) >= 4
}

# Edge case: Deleted resources should not trigger validations
test_delete_action_ignored if {
  result := wafandshield.deny with input as {
    "resource_changes": [
      {
        "address": "aws_wafv2_web_acl.test",
        "type": "aws_wafv2_web_acl",
        "change": {
          "actions": ["delete"],
          "before": {
            "name": "test-web-acl",
            "scope": "REGIONAL",
            "tags": {},
          },
        },
      },
    ],
  }
  count(result) == 0
}

# Warning conditions test: valid config but triggers warnings for missing best practices
test_warning_conditions if {
  result := wafandshield.warn with input as {
    "resource_changes": [
      {
        "address": "aws_wafv2_web_acl.test",
        "type": "aws_wafv2_web_acl",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "test-web-acl",
            "scope": "REGIONAL",
            "description": "Test WAF Web ACL",
            "default_action": [{"allow": {}}],
            "rule": [],
            "visibility_config": [
              {
                "cloudwatch_metrics_enabled": true,
                "metric_name": "test_web_acl",
                "sampled_requests_enabled": true,
              },
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
            },
          },
        },
      },
    ],
  }
  count(result) >= 3
}


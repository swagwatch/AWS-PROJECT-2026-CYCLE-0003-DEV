package terraform.aws.certificatemanager

import data.terraform.aws.certificatemanager

# Test 1: Valid certificate configuration - should have no deny violations
test_valid_certificate_no_violations if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.valid",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": ["www.example.com"],
            "validation_method": "DNS",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Count deny violations - should be 0
  denies := deny with input as input_plan
  count(denies) == 0
}

# Test 2: Missing required tags - should trigger deny violation
test_missing_required_tags if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.missing_tags",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev"
            }
          }
        }
      }
    ]
  }

  # Should have deny violations for missing Owner and Project tags
  denies := deny with input as input_plan
  count(denies) > 0

  # Check that the violation message mentions missing tags
  some violation_msg in denies
  contains(violation_msg, "missing required tags")
}

# Test 3: EMAIL validation method - should trigger deny violation
test_invalid_validation_method if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.email_validation",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "EMAIL",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have deny violation for EMAIL validation
  denies := deny with input as input_plan
  count(denies) > 0

  # Check that the violation message mentions EMAIL validation
  some violation_msg in denies
  contains(violation_msg, "EMAIL validation")
}

# Test 4: Transparency logging disabled - should trigger deny violation
test_transparency_logging_disabled if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.no_transparency",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "DISABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have deny violation for disabled transparency logging
  denies := deny with input as input_plan
  count(denies) > 0

  # Check that the violation message mentions transparency logging
  some violation_msg in denies
  contains(violation_msg, "transparency logging disabled")
}

# Test 5: Weak key algorithm - should trigger deny violation
test_weak_key_algorithm if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.weak_key",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "RSA_1024",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have deny violation for weak key algorithm
  denies := deny with input as input_plan
  count(denies) > 0

  # Check that the violation message mentions key algorithm
  some violation_msg in denies
  contains(violation_msg, "weak or unsupported key algorithm")
}

# Test 6: Empty domain name - should trigger deny violation
test_empty_domain_name if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.empty_domain",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have deny violation for empty domain name
  denies := deny with input as input_plan
  count(denies) > 0

  # Check that the violation message mentions empty domain name
  some violation_msg in denies
  contains(violation_msg, "empty domain name")
}

# Test 7: Delete action - should not trigger violations
test_delete_action_ignored if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.deleted",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["delete"],
          "after": null
        }
      }
    ]
  }

  # Should have no deny violations for delete actions
  denies := deny with input as input_plan
  count(denies) == 0
}

# Test 8: Wildcard certificate - should trigger warning but not deny
test_wildcard_certificate_warning if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.wildcard",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "*.example.com",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "RSA_2048",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have no deny violations (wildcard is warning only)
  denies := deny with input as input_plan
  count(denies) == 0

  # Should have warning for wildcard
  warns := warn with input as input_plan
  count(warns) > 0

  # Check that warning message mentions wildcard
  some warning_msg in warns
  contains(warning_msg, "wildcard")
}

# Test 9: Certificate with EC key algorithm - should be valid
test_ec_key_algorithm_valid if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.ec_cert",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "DNS",
            "key_algorithm": "EC_prime256v1",
            "options": [
              {
                "certificate_transparency_logging_preference": "ENABLED"
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "certificatemanager-module"
            }
          }
        }
      }
    ]
  }

  # Should have no deny violations for EC algorithm
  denies := deny with input as input_plan
  count(denies) == 0
}

# Test 10: Multiple violations - should trigger multiple denies
test_multiple_violations if {
  input_plan := {
    "resource_changes": [
      {
        "address": "aws_acm_certificate.multi_violations",
        "type": "aws_acm_certificate",
        "change": {
          "actions": ["create"],
          "after": {
            "domain_name": "example.com",
            "subject_alternative_names": [],
            "validation_method": "EMAIL",
            "key_algorithm": "RSA_1024",
            "options": [
              {
                "certificate_transparency_logging_preference": "DISABLED"
              }
            ],
            "tags": {
              "Environment": "dev"
            }
          }
        }
      }
    ]
  }

  # Should have multiple deny violations
  denies := deny with input as input_plan
  count(denies) >= 4  # Missing tags, EMAIL validation, disabled logging, weak algorithm
}

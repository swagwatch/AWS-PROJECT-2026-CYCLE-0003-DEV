package terraform.aws.eks

import future.keywords.if

# Test: Valid EKS configuration with all security features enabled
test_valid_eks_configuration_no_violations if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "test-cluster",
            "version": "1.28",
            "encryption_config": [
              {
                "provider": {"key_arn": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"},
                "resources": ["secrets"]
              }
            ],
            "enabled_cluster_log_types": ["api", "audit", "authenticator", "controllerManager", "scheduler"],
            "vpc_config": [
              {
                "endpoint_private_access": true,
                "endpoint_public_access": false,
                "public_access_cidrs": []
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "eks-infrastructure",
              "Name": "test-cluster"
            }
          }
        }
      },
      {
        "address": "module.eks.aws_eks_node_group.main[\"default\"]",
        "type": "aws_eks_node_group",
        "change": {
          "actions": ["create"],
          "after": {
            "node_group_name": "default",
            "node_role_arn": "arn:aws:iam::123456789012:role/eks-node-role",
            "instance_types": ["t3.medium"],
            "capacity_type": "ON_DEMAND",
            "scaling_config": [
              {
                "desired_size": 2,
                "max_size": 4,
                "min_size": 1
              }
            ],
            "update_config": [
              {
                "max_unavailable": 1
              }
            ]
          }
        }
      }
    ]
  }

  count(result) == 0
}

# Test: Invalid EKS configuration with multiple violations
test_invalid_eks_configuration_with_violations if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "bad-cluster",
            "version": "1.28",
            "encryption_config": [],
            "enabled_cluster_log_types": ["api"],
            "vpc_config": [
              {
                "endpoint_private_access": true,
                "endpoint_public_access": true,
                "public_access_cidrs": ["0.0.0.0/0"]
              }
            ],
            "tags": {
              "Name": "bad-cluster"
            }
          }
        }
      },
      {
        "address": "module.eks.aws_eks_node_group.main[\"default\"]",
        "type": "aws_eks_node_group",
        "change": {
          "actions": ["create"],
          "after": {
            "node_group_name": "default",
            "node_role_arn": "arn:aws:iam::123456789012:role/eks-node-role",
            "instance_types": ["t3.medium"],
            "capacity_type": "ON_DEMAND",
            "scaling_config": [
              {
                "desired_size": 2,
                "max_size": 4,
                "min_size": 1
              }
            ]
          }
        }
      }
    ]
  }

  count(result) > 0

  # Should have violations for:
  # 1. Missing encryption (encryption_config is empty)
  # 2. Missing required logs (audit, authenticator)
  # 3. Unrestricted public access (0.0.0.0/0)
  # 4. Missing required tags (Environment, Owner, Project)
}

# Test: Delete action should not trigger violations
test_delete_action_ignored if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["delete"],
          "after": null,
          "before": {
            "name": "cluster-to-delete",
            "encryption_config": [],
            "enabled_cluster_log_types": [],
            "vpc_config": [
              {
                "endpoint_private_access": false,
                "endpoint_public_access": true,
                "public_access_cidrs": ["0.0.0.0/0"]
              }
            ],
            "tags": {}
          }
        }
      }
    ]
  }

  # Delete actions should not trigger any violations
  count(result) == 0
}

# Test: Missing encryption violation
test_missing_encryption_violation if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "no-encryption-cluster",
            "version": "1.28",
            "enabled_cluster_log_types": ["api", "audit", "authenticator"],
            "vpc_config": [
              {
                "endpoint_private_access": true,
                "endpoint_public_access": false,
                "public_access_cidrs": []
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "eks-infrastructure"
            }
          }
        }
      }
    ]
  }

  count(result) > 0
  string_contains(result[_], "encryption")
}

# Test: Missing required tags violation
test_missing_required_tags_violation if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "no-tags-cluster",
            "version": "1.28",
            "encryption_config": [
              {
                "provider": {"key_arn": "arn:aws:kms:us-east-1:123456789012:key/test"},
                "resources": ["secrets"]
              }
            ],
            "enabled_cluster_log_types": ["api", "audit", "authenticator"],
            "vpc_config": [
              {
                "endpoint_private_access": true,
                "endpoint_public_access": false,
                "public_access_cidrs": []
              }
            ],
            "tags": {
              "Name": "no-tags-cluster"
            }
          }
        }
      }
    ]
  }

  count(result) > 0
  string_contains(result[_], "missing required tags")
}

# Test: Public endpoint without CIDR restrictions violation
test_public_endpoint_without_cidrs_violation if {
  result := deny with input as {
    "resource_changes": [
      {
        "address": "module.eks.aws_eks_cluster.main",
        "type": "aws_eks_cluster",
        "change": {
          "actions": ["create"],
          "after": {
            "name": "public-cluster",
            "version": "1.28",
            "encryption_config": [
              {
                "provider": {"key_arn": "arn:aws:kms:us-east-1:123456789012:key/test"},
                "resources": ["secrets"]
              }
            ],
            "enabled_cluster_log_types": ["api", "audit", "authenticator"],
            "vpc_config": [
              {
                "endpoint_private_access": true,
                "endpoint_public_access": true,
                "public_access_cidrs": ["0.0.0.0/0"]
              }
            ],
            "tags": {
              "Environment": "dev",
              "Owner": "platform-team",
              "Project": "eks-infrastructure"
            }
          }
        }
      }
    ]
  }

  count(result) > 0
  string_contains(result[_], "unrestricted CIDR")
}

# Helper function to check if a string contains a substring
string_contains(str, substr) if {
  indexof(str, substr) >= 0
}

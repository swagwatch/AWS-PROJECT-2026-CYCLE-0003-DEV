# EKS OPA Policy Rules

This directory contains Open Policy Agent (OPA) Rego policies for validating AWS EKS Terraform configurations against security and compliance requirements.

## Overview

The OPA policies evaluate Terraform plan JSON output to identify security violations and best practice warnings before resources are deployed. Policies are organized into two categories:

- **DENY Rules**: Critical violations that must be fixed before deployment
- **WARN Rules**: Best practice recommendations that should be addressed

## Policy Validation Workflow

1. Generate Terraform plan: `terraform plan -out=tfplan.binary`
2. Convert plan to JSON: `terraform show -json tfplan.binary > tfplan.json`
3. Validate with OPA: `opa eval -d main.rego -i tfplan.json "data.terraform.aws.eks.deny"`
4. Fix any violations and repeat

## DENY Rules (Critical)

### 1. Encryption Required

**Rule**: EKS clusters must have encryption enabled for Kubernetes secrets using AWS KMS.

**Violation Example**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  # Missing encryption_config block
}
```

**Fix**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  encryption_config {
    provider {
      key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
    resources = ["secrets"]
  }
}
```

### 2. Control Plane Logging Required

**Rule**: EKS clusters must have at least `api`, `audit`, and `authenticator` logging enabled.

**Violation Example**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  enabled_cluster_log_types = ["api"]  # Missing audit and authenticator
}
```

**Fix**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  enabled_cluster_log_types = ["api", "audit", "authenticator"]
}
```

### 3. Public Endpoint Restrictions

**Rule**: If public endpoint access is enabled, it must be restricted to specific CIDR blocks (not 0.0.0.0/0).

**Violation Example**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]  # Unrestricted access
  }
}
```

**Fix**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_public_access = true
    public_access_cidrs    = ["203.0.113.0/24", "198.51.100.0/24"]  # Specific IPs
  }
}
```

**Better Fix** (Recommended):
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false  # Private only
  }
}
```

### 4. Required Tags

**Rule**: All EKS clusters must have `Environment`, `Owner`, and `Project` tags.

**Violation Example**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  tags = {
    Name = "my-cluster"
  }
}
```

**Fix**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  tags = {
    Name        = "my-cluster"
    Environment = "production"
    Owner       = "platform-team"
    Project     = "eks-infrastructure"
  }
}
```

### 5. Node Group IAM Role Required

**Rule**: All node groups must have a valid IAM role ARN configured.

**Violation Example**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name
  # Missing node_role_arn
}
```

**Fix**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name  = aws_eks_cluster.main.name
  node_role_arn = aws_iam_role.node.arn
}
```

### 6. Deprecated Instance Types

**Rule**: Node groups must not use deprecated instance types (t1, m1, m2, c1 families).

**Violation Example**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name   = aws_eks_cluster.main.name
  instance_types = ["m1.large"]  # Deprecated
}
```

**Fix**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name   = aws_eks_cluster.main.name
  instance_types = ["m5.large"]  # Current generation
}
```

### 7. Endpoint Access Required

**Rule**: At least one of private or public endpoint access must be enabled.

**Violation Example**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = false  # Both disabled
  }
}
```

**Fix**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
  }
}
```

## WARN Rules (Best Practices)

### 1. Private-Only Endpoint Access Recommended

**Rule**: For better security, use private-only endpoint access.

**Warning Trigger**:
```hcl
resource "aws_eks_cluster" "main" {
  name = "my-cluster"
  vpc_config {
    endpoint_public_access = true  # Triggers warning
  }
}
```

**Recommendation**: Disable public access and use VPN or AWS PrivateLink for cluster access.

### 2. Node Group Update Strategy

**Rule**: Node groups should have `update_config` specified for controlled rolling updates.

**Warning Trigger**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name
  # Missing update_config
}
```

**Recommendation**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name
  update_config {
    max_unavailable = 1
  }
}
```

### 3. Kubernetes Version Currency

**Rule**: Use Kubernetes version 1.27 or higher for latest features and security patches.

**Warning Trigger**:
```hcl
resource "aws_eks_cluster" "main" {
  name    = "my-cluster"
  version = "1.24"  # Triggers warning
}
```

**Recommendation**: Upgrade to 1.27 or higher.

### 4. Node Group High Availability

**Rule**: Node groups should have `min_size` of at least 1 for high availability.

**Warning Trigger**:
```hcl
resource "aws_eks_node_group" "main" {
  scaling_config {
    min_size = 0  # Triggers warning
  }
}
```

**Recommendation**: Set `min_size` to at least 1 to ensure availability.

### 5. Capacity Type Specification

**Rule**: Consider specifying `capacity_type` (ON_DEMAND or SPOT) for cost optimization.

**Info Trigger**:
```hcl
resource "aws_eks_node_group" "main" {
  cluster_name = aws_eks_cluster.main.name
  # Missing capacity_type
}
```

**Recommendation**: Use SPOT instances for non-critical workloads to reduce costs.

## Running Policy Tests

Execute policy unit tests to validate rule logic:

```bash
# Run all tests
opa test modules/eks/policy/ -v

# Expected output: PASS: X/X
```

## Checking Policy Syntax

Verify policy syntax is valid:

```bash
opa check modules/eks/policy/main.rego modules/eks/policy/test.rego
```

## Common Policy Violations and Fixes

### Violation: Multiple Issues

If you encounter multiple violations, address them in order of severity:

1. Fix all CRITICAL (deny) violations first
2. Review and address WARN violations
3. Re-run terraform plan and OPA validation

### Troubleshooting Policy Evaluation

If OPA evaluation fails:

1. Verify `tfplan.json` is valid JSON: `jq . tfplan.json`
2. Check that `resource_changes` array exists in the plan
3. Ensure policy file path is correct in OPA eval command
4. Verify OPA version is 0.40.0 or higher

## Integration with CI/CD

These policies are automatically enforced in the CI/CD pipeline:

1. **Pre-commit Hook**: Validates policies locally before commit
2. **GitHub Actions**: Runs policy validation on pull requests
3. **Terraform Plan**: Generates plan and validates against policies

To bypass validation locally (not recommended):
```bash
git commit --no-verify
```

## Policy Customization

To add custom rules:

1. Add new rule to `main.rego` following the pattern
2. Add corresponding test cases to `test.rego`
3. Run `opa test` to verify tests pass
4. Update this README with the new rule documentation

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Terraform Plan JSON Format](https://www.terraform.io/internals/json-format)
- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/)

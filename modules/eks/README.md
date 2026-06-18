# AWS EKS Terraform Module

This module provisions an Amazon Elastic Kubernetes Service (EKS) cluster with managed node groups, security features, and IAM roles for service accounts (IRSA).

## Features

- EKS cluster with configurable Kubernetes version
- Managed node groups with auto-scaling
- KMS encryption for Kubernetes secrets
- Control plane logging (API, audit, authenticator, controller manager, scheduler)
- Private and public endpoint access control
- IAM Roles for Service Accounts (IRSA) with OIDC provider
- Configurable node group settings (instance types, capacity type, taints, labels)
- Automated IAM role creation for cluster and nodes
- Comprehensive tagging support

## Usage

### Basic Example

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.28"

  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  enable_encryption = true
  kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  node_groups = {
    default = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
    }
  }

  common_tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "eks-infrastructure"
  }
}
```

### Advanced Example with Multiple Node Groups

```hcl
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.28"

  subnet_ids                 = ["subnet-12345678", "subnet-87654321"]
  endpoint_private_access    = true
  endpoint_public_access     = false

  enable_encryption = true
  kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  enable_irsa = true

  node_groups = {
    general = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      labels = {
        role = "general"
      }
      update_config = {
        max_unavailable = 1
      }
    }
    spot = {
      desired_size   = 1
      max_size       = 3
      min_size       = 0
      instance_types = ["t3.large", "t3a.large"]
      capacity_type  = "SPOT"
      labels = {
        role = "spot"
      }
    }
  }

  common_tags = {
    Environment = "production"
    Owner       = "platform-team"
    Project     = "eks-infrastructure"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.4.0 |
| aws | >= 5.0.0 |
| tls | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| kubernetes_version | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| subnet_ids | List of subnet IDs for the EKS cluster and node groups | `list(string)` | n/a | yes |
| cluster_security_group_ids | Additional security group IDs to attach to the EKS cluster | `list(string)` | `[]` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `false` | no |
| public_access_cidrs | List of CIDR blocks that can access the public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| enable_encryption | Enable encryption of Kubernetes secrets using KMS | `bool` | `true` | no |
| kms_key_arn | ARN of the KMS key to use for encryption | `string` | `null` | no |
| enabled_cluster_log_types | List of control plane logging types to enable | `list(string)` | `["api", "audit", "authenticator"]` | no |
| node_groups | Map of node group configurations | `map(object)` | `{}` | no |
| create_cluster_role | Whether to create an IAM role for the EKS cluster | `bool` | `true` | no |
| cluster_role_arn | IAM role ARN for the EKS cluster | `string` | `null` | no |
| create_node_role | Whether to create an IAM role for the node groups | `bool` | `true` | no |
| enable_irsa | Enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |
| common_tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The name/id of the EKS cluster |
| cluster_arn | The Amazon Resource Name (ARN) of the cluster |
| cluster_endpoint | Endpoint for your Kubernetes API server |
| cluster_version | The Kubernetes server version for the cluster |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_iam_role_arn | IAM role ARN of the EKS cluster |
| node_iam_role_arn | IAM role ARN of the EKS node groups |
| node_iam_role_name | IAM role name of the EKS node groups |
| oidc_provider_arn | ARN of the OIDC Provider for EKS |
| oidc_provider_url | URL of the OIDC Provider for EKS |
| cluster_certificate_authority_data | Base64 encoded certificate data (sensitive) |
| node_groups | Outputs from EKS node groups |
| cluster_vpc_config | VPC configuration of the cluster |

## Security Best Practices

This module enforces several security best practices:

- **Encryption at Rest**: Kubernetes secrets are encrypted using AWS KMS
- **Control Plane Logging**: API, audit, and authenticator logs are enabled by default
- **Private Endpoint**: Private API access is enabled by default
- **Public Endpoint Restrictions**: Public access can be restricted to specific CIDR blocks
- **IAM Roles for Service Accounts**: OIDC provider is created for fine-grained pod-level IAM permissions
- **Required Tags**: Resources must be tagged with Environment, Owner, and Project

## Prerequisites

Before using this module, ensure you have:

1. VPC with at least 2 subnets in different availability zones
2. KMS key created for encryption (if enable_encryption is true)
3. Appropriate IAM permissions to create EKS clusters, node groups, and IAM roles

## Links

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider - EKS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)

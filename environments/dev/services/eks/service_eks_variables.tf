# Cluster Configuration Variables
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  type        = string
  default     = null
}

variable "create_cluster_role" {
  description = "Whether to create an IAM role for the EKS cluster"
  type        = bool
  default     = true
}

# VPC Configuration Variables
variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
  default     = ["subnet-12345678", "subnet-87654321"]
}

variable "cluster_security_group_ids" {
  description = "Additional security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

# Endpoint Access Variables
variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks for public API access"
  type        = list(string)
  default     = []
}

# Encryption Variables
variable "enable_encryption" {
  description = "Enable encryption of Kubernetes secrets"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}

# Logging Variables
variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Node Groups Variables
variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    desired_size     = number
    max_size         = number
    min_size         = number
    instance_types   = list(string)
    capacity_type    = optional(string)
    disk_size        = optional(number)
    node_role_arn    = optional(string)
    subnet_ids       = optional(list(string))
    labels           = optional(map(string))
    taints           = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })))
    update_config    = optional(object({
      max_unavailable_percentage = optional(number)
      max_unavailable            = optional(number)
    }))
    tags             = optional(map(string))
  }))
  default = {
    default = {
      desired_size   = 2
      max_size       = 4
      min_size       = 1
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      update_config = {
        max_unavailable = 1
      }
    }
  }
}

variable "create_node_role" {
  description = "Whether to create an IAM role for node groups"
  type        = bool
  default     = true
}

# IRSA Variables
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

# Tagging Variables
variable "tags" {
  description = "Additional tags for EKS resources"
  type        = map(string)
  default     = {}
}

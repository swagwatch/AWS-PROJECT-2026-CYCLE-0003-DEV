package terraform.aws.eks

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

# DENY: EKS cluster must have encryption enabled for secrets
deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after

  not after.encryption_config

  msg := sprintf("CRITICAL: EKS cluster '%s' must have encryption enabled for Kubernetes secrets. Add encryption_config block with a KMS key ARN.", [cluster.address])
}

deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after

  count(after.encryption_config) == 0

  msg := sprintf("CRITICAL: EKS cluster '%s' must have encryption enabled for Kubernetes secrets. Add encryption_config block with a KMS key ARN.", [cluster.address])
}

# DENY: EKS cluster must have control plane logging enabled (api, audit, authenticator)
deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after

  required_logs := {"api", "audit", "authenticator"}
  enabled_logs := {log | log := after.enabled_cluster_log_types[_]}
  missing_logs := required_logs - enabled_logs
  count(missing_logs) > 0

  msg := sprintf("CRITICAL: EKS cluster '%s' must have control plane logging enabled for: %v. Current enabled logs: %v", [cluster.address, missing_logs, enabled_logs])
}

# DENY: EKS cluster with public endpoint must have CIDR restrictions
deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after
  vpc_config := after.vpc_config[0]

  vpc_config.endpoint_public_access == true
  public_cidrs := {cidr | cidr := vpc_config.public_access_cidrs[_]}
  array_contains(vpc_config.public_access_cidrs, "0.0.0.0/0")

  msg := sprintf("CRITICAL: EKS cluster '%s' has public endpoint access enabled with unrestricted CIDR (0.0.0.0/0). Restrict public access to specific IP ranges or disable public access.", [cluster.address])
}

# DENY: EKS cluster must have required tags (Environment, Owner, Project)
deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after
  tags := get_tags(after)

  required_tags := {"Environment", "Owner", "Project"}
  existing_tags := {tag | tags[tag]}
  missing_tags := required_tags - existing_tags
  count(missing_tags) > 0

  msg := sprintf("CRITICAL: EKS cluster '%s' is missing required tags: %v. All clusters must have Environment, Owner, and Project tags.", [cluster.address, missing_tags])
}

# DENY: Node groups must have proper IAM role configuration
deny contains msg if {
  node_group := resource_changes_by_type("aws_eks_node_group")[_]
  after := node_group.change.after
  after_unknown := node_group.change.after_unknown

  # Check if node_role_arn is neither set nor will be computed
  not after.node_role_arn
  not after_unknown.node_role_arn

  msg := sprintf("CRITICAL: EKS node group '%s' must have a valid IAM role ARN configured.", [node_group.address])
}

# DENY: Node groups must not use deprecated or unsupported instance types
deny contains msg if {
  node_group := resource_changes_by_type("aws_eks_node_group")[_]
  after := node_group.change.after

  deprecated_instance_families := {"t1", "m1", "m2", "c1"}
  instance_type := after.instance_types[_]
  instance_family := split(instance_type, ".")[0]
  deprecated_instance_families[instance_family]

  msg := sprintf("CRITICAL: EKS node group '%s' uses deprecated instance type '%s'. Use current generation instance types (t3, t4g, m5, m6i, etc.).", [node_group.address, instance_type])
}

# DENY: EKS cluster must have at least private endpoint access enabled
deny contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after
  vpc_config := after.vpc_config[0]

  vpc_config.endpoint_private_access == false
  vpc_config.endpoint_public_access == false

  msg := sprintf("CRITICAL: EKS cluster '%s' has both public and private endpoint access disabled. At least one must be enabled.", [cluster.address])
}

# ------------------------
# WARN Rules (Cost Optimization Best Practices)
# ------------------------

# WARN: EKS cluster should prefer private-only endpoint access
warn contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after
  vpc_config := after.vpc_config[0]

  vpc_config.endpoint_public_access == true

  msg := sprintf("WARNING: EKS cluster '%s' has public endpoint access enabled. For better security, consider using private-only endpoint access.", [cluster.address])
}

# WARN: Node groups should have update strategy configured
warn contains msg if {
  node_group := resource_changes_by_type("aws_eks_node_group")[_]
  after := node_group.change.after

  not after.update_config

  msg := sprintf("WARNING: EKS node group '%s' does not have update_config specified. Consider configuring max_unavailable or max_unavailable_percentage for controlled updates.", [node_group.address])
}

# WARN: EKS cluster should use latest stable Kubernetes version
warn contains msg if {
  cluster := resource_changes_by_type("aws_eks_cluster")[_]
  after := cluster.change.after

  version_parts := split(after.version, ".")
  major := to_number(version_parts[0])
  minor := to_number(version_parts[1])

  minor < 27

  msg := sprintf("WARNING: EKS cluster '%s' is using Kubernetes version %s. Consider upgrading to a more recent version (1.27 or higher) for latest features and security patches.", [cluster.address, after.version])
}

# WARN: Node groups should have appropriate sizing (min_size should be at least 1 for HA)
warn contains msg if {
  node_group := resource_changes_by_type("aws_eks_node_group")[_]
  after := node_group.change.after
  scaling_config := after.scaling_config[0]

  scaling_config.min_size < 1

  msg := sprintf("WARNING: EKS node group '%s' has min_size of %d. For high availability, consider setting min_size to at least 1.", [node_group.address, scaling_config.min_size])
}

# WARN: Node groups should use appropriate capacity type (consider SPOT for cost savings on non-critical workloads)
warn contains msg if {
  node_group := resource_changes_by_type("aws_eks_node_group")[_]
  after := node_group.change.after

  not after.capacity_type

  msg := sprintf("INFO: EKS node group '%s' does not specify capacity_type. Consider using SPOT instances for cost savings on non-critical workloads.", [node_group.address])
}

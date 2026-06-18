# Computed values for conditional resource creation
locals {
  # Use created role ARN if create_cluster_role is true, otherwise use provided ARN
  cluster_role_arn = var.create_cluster_role ? aws_iam_role.cluster[0].arn : var.cluster_role_arn
}

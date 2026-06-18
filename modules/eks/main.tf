# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = var.cluster_security_group_ids
  }

  dynamic "encryption_config" {
    for_each = var.enable_encryption ? [1] : []
    content {
      provider {
        key_arn = var.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  tags = merge(
    var.common_tags,
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
  ]
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  count = var.create_cluster_role ? 1 : 0

  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role[0].json

  tags = merge(
    var.common_tags,
    var.tags,
    {
      Name = "${var.cluster_name}-cluster-role"
    }
  )
}

data "aws_iam_policy_document" "cluster_assume_role" {
  count = var.create_cluster_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = var.create_cluster_role ? aws_iam_role.cluster[0].name : basename(var.cluster_role_arn)
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# OIDC Provider for IRSA
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.common_tags,
    var.tags,
    {
      Name = "${var.cluster_name}-irsa"
    }
  )
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = each.key
  node_role_arn   = var.create_node_role ? aws_iam_role.node[0].arn : each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  instance_types = each.value.instance_types
  capacity_type  = lookup(each.value, "capacity_type", "ON_DEMAND")
  disk_size      = lookup(each.value, "disk_size", 20)

  dynamic "update_config" {
    for_each = lookup(each.value, "update_config", null) != null ? [each.value.update_config] : []
    content {
      max_unavailable_percentage = lookup(update_config.value, "max_unavailable_percentage", null)
      max_unavailable            = lookup(update_config.value, "max_unavailable", null)
    }
  }

  labels = lookup(each.value, "labels", {})

  dynamic "taint" {
    for_each = lookup(each.value, "taints", null) != null ? each.value.taints : []
    content {
      key    = taint.value.key
      value  = lookup(taint.value, "value", null)
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.common_tags,
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = "${var.cluster_name}-${each.key}"
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_policy,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS Node Group IAM Role
resource "aws_iam_role" "node" {
  count = var.create_node_role ? 1 : 0

  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role[0].json

  tags = merge(
    var.common_tags,
    var.tags,
    {
      Name = "${var.cluster_name}-node-role"
    }
  )
}

data "aws_iam_policy_document" "node_assume_role" {
  count = var.create_node_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  count = var.create_node_role ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  count = var.create_node_role ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy" {
  count = var.create_node_role ? 1 : 0

  role       = aws_iam_role.node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

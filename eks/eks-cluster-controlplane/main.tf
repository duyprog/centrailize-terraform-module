# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN ELASTIC CONTAINER SERVICE FOR KUBERNETES (EKS) CLUSTER
# These templates launch an EKS cluster resource that manages the EKS control plane. This includes:
# - Security group
# - IAM roles and policies
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ---------------------------------------------------------------------------------------------------------------------
# SET TERRAFORM REQUIREMENTS FOR RUNNING THIS MODULE
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = "~> 5.0"
    tls = "~> 4.0.0"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks.arn
  version  = var.kubernetes_version
  # enabled_cluster_log_types = var.enabled_cluster_log_types
  vpc_config {
    security_group_ids     = concat(compact(var.additional_security_groups), [aws_security_group.eks.id])
    subnet_ids             = var.vpc_control_plane_subnet_ids
    endpoint_public_access = var.endpoint_public_access
    public_access_cidrs    = var.endpoint_private_access_cidrs

    # Always enable private API access, since nodes still need to access the API 
    endpoint_private_access = true
  }

  # dynamic "encryption_config" {
  # }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,

    # Make sure CloudWatch log group is created before creating the EKS cluster
    aws_cloudwatch_log_group.control_plane_logs
  ]

  timeouts {
    create = "1h"
    delete = "1h"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AWS CLOUDWATCH LOG GROUP FOR CONTROL PLANE LOGGING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "control_plane_logs" {
  count             = var.create_cloudwatch_log_group ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  tags              = var.cloudwatch_log_group_tags
}


# ---------------------------------------------------------------------------------------------------------------------
# IAM ROLE AND POLICIES FOR THE CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "allow_eks_to_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eks" {
  name                 = "${var.cluster_name}-eks"
  assume_role_policy   = data.aws_iam_policy_document.allow_eks_to_assume_role.json
  permissions_boundary = var.cluster_iam_role_permissions_boundary

  # IAM objects take time to create. This leads to subtle eventual consistency bugs where EKS cluster cannot
  # be created because IAM role doesn't exists
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to wait for IAM role to be created'; sleep 30"
  }
}

# EKS requires the following IAM policies to function 
# - Creating and listing tags on EC2 
# - Allocating a Load Balancer
# Using KMS keys for encryption/decryption

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name

  # IAM objects take time to create. This leads to subtle eventual consistency bugs where EKS cluster cannot
  # be created because IAM role doesn't exists
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to wait for IAM role to be created'; sleep 30"
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name

  # IAM objects take time to create. This leads to subtle eventual consistency bugs where EKS cluster cannot
  # be created because IAM role doesn't exists
  provisioner "local-exec" {
    command = "echo 'Sleeping for 30 seconds to wait for IAM role to be created'; sleep 30"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUP FOR EKS CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "eks" {
  name        = "${var.cluster_name}-sg"
  description = "Allow Kubernetes Control Plane of ${var.cluster_name} to communicate with workder nodes"
  vpc_id      = var.vpc_id
  tags        = var.custom_tags_security_group
}

resource "aws_security_group_rule" "allow_outbound_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "allow_inbound_api_cidr" {
  count = length(var.endpoint_private_access_cidrs) > 0 ? 1 : 0 
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = var.endpoint_private_access_cidrs
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "allow_inbound_api_sg" {
  for_each = var.endpoint_private_access_security_group_ids
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  source_security_group_id = each.value
  security_group_id = aws_security_group.eks.id
}

# ---------------------------------------------------------------------------------------------------------------------
# PROVISION OPENID CONNECT PROVIDER 
# ---------------------------------------------------------------------------------------------------------------------

data "tls_certificate" "oidc_thumbprint" {
  count = (var.configure_openid_connect_provider && var.openid_connect_provider_thumbprint == null) ? 1 : 0 
  url = local.maybe_issuer_url 
}

locals {
  maybe_issuer_url = length(aws_eks_cluster.eks.identity) > 0 ? aws_eks_cluster.eks.identity.0.oidc.0.issuer : null 
  thumbprint = (
    var.openid_connect_provider_thumbprint != null
    ? var.openid_connect_provider_thumbprint
    : (
      length(data.tls_certificate.oidc_thumbprint) > 0
      ? data.tls_certificate.oidc_thumbprint[0].certificates[0].sha1_fingerprint : null 
    )
  )
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.configure_openid_connect_provider ? 1 : 0 
  client_id_list = ["sts.amazonaws.com"]
  url = local.maybe_issuer_url 
  thumbprint_list = [local.thumbprint]
}




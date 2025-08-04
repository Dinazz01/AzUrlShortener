# ECR Module with Custom KMS Key
# This module creates an Amazon ECR repository with a custom KMS key for encryption

# Data source to get current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  count = var.create_kms_key ? 1 : 0

  description             = var.kms_key_description != null ? var.kms_key_description : "KMS key for ECR repository ${var.repository_name}"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.enable_kms_key_rotation
  multi_region           = var.kms_key_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR Service"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ecr.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "Allow key administrators"
        Effect = "Allow"
        Principal = {
          AWS = var.kms_key_administrators
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow key users"
        Effect = "Allow"
        Principal = {
          AWS = var.kms_key_users
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = var.kms_key_alias != null ? var.kms_key_alias : "ecr-${var.repository_name}"
      Purpose     = "ECR encryption"
      Repository  = var.repository_name
    }
  )
}

# Create KMS alias for easier reference
resource "aws_kms_alias" "ecr" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.kms_key_alias != null ? var.kms_key_alias : "ecr-${var.repository_name}"}"
  target_key_id = aws_kms_key.ecr[0].key_id
}

# Create ECR Repository
resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete        = var.force_delete

  encryption_configuration {
    encryption_type = var.create_kms_key ? "KMS" : var.encryption_type
    kms_key         = var.create_kms_key ? aws_kms_key.ecr[0].arn : var.existing_kms_key_arn
  }

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

# ECR Repository Policy
resource "aws_ecr_repository_policy" "this" {
  count = var.repository_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  count = var.lifecycle_policy != null ? 1 : 0

  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

# Default lifecycle policy for untagged images
resource "aws_ecr_lifecycle_policy" "default" {
  count = var.lifecycle_policy == null && var.enable_default_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.lifecycle_policy_max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.lifecycle_policy_max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.lifecycle_policy_untagged_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.lifecycle_policy_untagged_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
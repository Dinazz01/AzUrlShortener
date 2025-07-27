# ECR Repository
resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id
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
  count      = var.repository_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.repository_policy
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "this" {
  count      = var.lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.this.name
  policy     = var.lifecycle_policy
}

# Default Lifecycle Policy (if no custom policy provided)
resource "aws_ecr_lifecycle_policy" "default" {
  count      = var.lifecycle_policy == null && var.enable_default_lifecycle_policy ? 1 : 0
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete images older than ${var.max_image_age_days} days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.max_image_age_days
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Keep only latest untagged image"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Registry Scanning Configuration
resource "aws_ecr_registry_scanning_configuration" "this" {
  count = var.enable_registry_scanning ? 1 : 0

  scan_type = var.registry_scan_type

  dynamic "rule" {
    for_each = var.registry_scan_rules
    content {
      scan_frequency = rule.value.scan_frequency
      repository_filter {
        filter      = rule.value.repository_filter
        filter_type = rule.value.filter_type
      }
    }
  }
}

# ECR Replication Configuration
resource "aws_ecr_replication_configuration" "this" {
  count = length(var.replication_destinations) > 0 ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.replication_destinations
      content {
        dynamic "destination" {
          for_each = rule.value
          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }
        dynamic "repository_filter" {
          for_each = var.replication_repository_filters
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

# ECR Pull Through Cache Rules
resource "aws_ecr_pull_through_cache_rule" "this" {
  for_each = var.pull_through_cache_rules

  ecr_repository_prefix = each.value.ecr_repository_prefix
  upstream_registry_url = each.value.upstream_registry_url
  credential_arn        = each.value.credential_arn
}

# IAM Role for ECR Cross-Account Access (Optional)
resource "aws_iam_role" "ecr_cross_account" {
  count = var.create_cross_account_role ? 1 : 0
  name  = "${var.repository_name}-ecr-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.cross_account_arns
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for ECR Cross-Account Access
resource "aws_iam_role_policy" "ecr_cross_account" {
  count = var.create_cross_account_role ? 1 : 0
  name  = "${var.repository_name}-ecr-cross-account-policy"
  role  = aws_iam_role.ecr_cross_account[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchDeleteImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = aws_ecr_repository.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}
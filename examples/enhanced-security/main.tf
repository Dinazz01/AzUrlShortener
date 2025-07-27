# Enhanced Security ECR Repository Example
# This example demonstrates security-focused ECR configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 7

  tags = {
    Name        = "ecr-encryption-key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-encryption"
  target_key_id = aws_kms_key.ecr.key_id
}

# Enhanced security ECR repository
module "ecr_secure" {
  source = "../../modules/ecr"

  repository_name      = var.repository_name
  image_tag_mutability = "IMMUTABLE" # Prevent tag overwrites
  scan_on_push        = true         # Scan images on push
  encryption_type     = "KMS"        # Use KMS encryption
  kms_key_id          = aws_kms_key.ecr.arn

  # Enable enhanced registry scanning
  enable_registry_scanning = true
  registry_scan_type      = "ENHANCED"
  
  registry_scan_rules = [
    {
      scan_frequency     = "SCAN_ON_PUSH"
      repository_filter  = "${var.repository_name}*"
      filter_type        = "WILDCARD"
    }
  ]

  # Strict lifecycle policy for production
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep staging images for 7 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # Repository policy for restricted access
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowProductionAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.allowed_principals
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPushFromCI"
        Effect = "Allow"
        Principal = {
          AWS = var.ci_role_arn
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })

  tags = {
    Environment = "production"
    Security    = "high"
    Compliance  = "required"
    Team        = "security"
  }
}

# Outputs
output "repository_url" {
  description = "ECR repository URL"
  value       = module.ecr_secure.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr_secure.repository_arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = aws_kms_key.ecr.arn
}
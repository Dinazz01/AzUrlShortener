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
  region = "us-west-2"
}

# Get current AWS caller identity
data "aws_caller_identity" "current" {}

# Advanced ECR repository with comprehensive configuration
module "ecr_advanced" {
  source = "../../modules/ecr"

  repository_name      = "my-production-app"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  force_delete        = false

  # KMS Configuration
  create_kms_key                  = true
  kms_key_description            = "KMS key for production ECR repository encryption"
  kms_key_alias                  = "ecr-production-key"
  kms_key_deletion_window_in_days = 30
  enable_kms_key_rotation        = true
  kms_key_multi_region           = false
  
  # KMS Permissions
  kms_key_administrators = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AdminRole"
  ]
  kms_key_users = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ECSTaskRole",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/EKSNodeRole"
  ]

  # Repository Policy - Allow specific accounts to pull images
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            # Add other account IDs that need access
            # "arn:aws:iam::123456789012:root"
          ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })

  # Custom Lifecycle Policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "feature"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Delete untagged images older than 1 day"
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

  tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
    CostCenter  = "engineering"
    Compliance  = "required"
  }
}

# Example with existing KMS key
module "ecr_with_existing_kms" {
  source = "../../modules/ecr"

  repository_name = "my-shared-app"
  
  # Use existing KMS key
  create_kms_key       = false
  encryption_type      = "KMS"
  existing_kms_key_arn = "arn:aws:kms:us-west-2:${data.aws_caller_identity.current.account_id}:key/12345678-1234-1234-1234-123456789012"

  # Disable default lifecycle policy and provide custom one
  enable_default_lifecycle_policy = false
  
  tags = {
    Environment = "shared"
    Project     = "shared-services"
  }
}

# Outputs
output "production_repository_url" {
  description = "Production repository URL"
  value       = module.ecr_advanced.repository_url
}

output "production_kms_key_alias" {
  description = "Production KMS key alias"
  value       = module.ecr_advanced.kms_key_alias
}

output "all_docker_commands" {
  description = "All Docker commands for the production repository"
  value       = module.ecr_advanced.docker_commands
  sensitive   = true
}

output "shared_repository_url" {
  description = "Shared repository URL"
  value       = module.ecr_with_existing_kms.repository_url
}
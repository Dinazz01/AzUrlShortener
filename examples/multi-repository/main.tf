# Multi-Repository ECR Example
# This example creates multiple ECR repositories with different configurations

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

# Define multiple repositories with different configurations
locals {
  repositories = {
    frontend = {
      repository_name      = "frontend-web-app"
      image_tag_mutability = "MUTABLE"
      max_image_count      = 15
      max_image_age_days   = 21
      scan_on_push        = true
      environment         = "staging"
    }
    backend = {
      repository_name      = "backend-api-service"
      image_tag_mutability = "IMMUTABLE"
      max_image_count      = 25
      max_image_age_days   = 60
      scan_on_push        = true
      environment         = "production"
    }
    worker = {
      repository_name      = "background-worker"
      image_tag_mutability = "MUTABLE"
      max_image_count      = 5
      max_image_age_days   = 14
      scan_on_push        = false
      environment         = "development"
    }
    database = {
      repository_name      = "database-migration"
      image_tag_mutability = "IMMUTABLE"
      max_image_count      = 10
      max_image_age_days   = 90
      scan_on_push        = true
      environment         = "production"
    }
  }
}

# Create multiple ECR repositories
module "ecr_repositories" {
  source = "../../modules/ecr"
  
  for_each = local.repositories

  repository_name      = each.value.repository_name
  image_tag_mutability = each.value.image_tag_mutability
  scan_on_push        = each.value.scan_on_push
  max_image_count     = each.value.max_image_count
  max_image_age_days  = each.value.max_image_age_days

  # Enable enhanced scanning for production repositories
  enable_registry_scanning = each.value.environment == "production" ? true : false
  registry_scan_type      = each.value.environment == "production" ? "ENHANCED" : "BASIC"

  # Different encryption for production vs non-production
  encryption_type = each.value.environment == "production" ? "KMS" : "AES256"
  kms_key_id     = each.value.environment == "production" ? aws_kms_key.ecr[0].arn : null

  tags = {
    Environment = each.value.environment
    Service     = each.key
    Team        = var.team_name
    ManagedBy   = "terraform"
  }
}

# KMS key for production repositories
resource "aws_kms_key" "ecr" {
  count = length([for k, v in local.repositories : k if v.environment == "production"]) > 0 ? 1 : 0
  
  description             = "KMS key for production ECR repositories"
  deletion_window_in_days = 7

  tags = {
    Name        = "ecr-production-encryption-key"
    Environment = "production"
    Team        = var.team_name
  }
}

resource "aws_kms_alias" "ecr" {
  count = length(aws_kms_key.ecr) > 0 ? 1 : 0
  
  name          = "alias/ecr-production-encryption"
  target_key_id = aws_kms_key.ecr[0].key_id
}

# Outputs for all repositories
output "repository_urls" {
  description = "Map of repository names to their URLs"
  value = {
    for k, v in module.ecr_repositories : k => v.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository names to their ARNs"
  value = {
    for k, v in module.ecr_repositories : k => v.repository_arn
  }
}

output "repository_registry_url" {
  description = "The ECR registry URL"
  value       = values(module.ecr_repositories)[0].repository_registry_url
}

output "production_repositories" {
  description = "List of production repository names"
  value = [
    for k, v in local.repositories : v.repository_name
    if v.environment == "production"
  ]
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for production repositories"
  value       = length(aws_kms_key.ecr) > 0 ? aws_kms_key.ecr[0].arn : null
}
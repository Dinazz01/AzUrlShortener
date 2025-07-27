# Root Configuration Example
# This shows how to use the ECR module in your main Terraform configuration

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment and configure for production use
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "ecr/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

provider "aws" {
  region = var.aws_region

  # Uncomment for production use
  # assume_role {
  #   role_arn = "arn:aws:iam::ACCOUNT:role/TerraformRole"
  # }

  default_tags {
    tags = {
      Project     = "ECR-Demo"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Data sources for current AWS account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Example: Simple ECR repository
module "simple_app_ecr" {
  source = "./modules/ecr"

  repository_name = "simple-web-app"
  
  tags = {
    Application = "SimpleApp"
    Team        = "Frontend"
  }
}

# Example: Production ECR repository with enhanced security
module "production_api_ecr" {
  source = "./modules/ecr"

  repository_name      = "production-api"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  encryption_type     = "AES256"  # Use KMS for higher security needs

  # Custom lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
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

  tags = {
    Application = "ProductionAPI"
    Team        = "Backend"
    Environment = "production"
    Criticality = "high"
  }
}

# Outputs
output "simple_app_repository_url" {
  description = "Simple app ECR repository URL"
  value       = module.simple_app_ecr.repository_url
}

output "production_api_repository_url" {
  description = "Production API ECR repository URL"
  value       = module.production_api_ecr.repository_url
}

output "ecr_login_command" {
  description = "AWS CLI command to log in to ECR"
  value       = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com"
}
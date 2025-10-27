# Basic ECR Repository Example
# This example creates a simple ECR repository with default settings

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

# Basic ECR repository
module "ecr_basic" {
  source = "../../modules/ecr"

  repository_name = var.repository_name

  tags = {
    Environment = "development"
    Team        = "platform"
    Example     = "basic"
  }
}

# Output the repository details
output "repository_url" {
  description = "ECR repository URL"
  value       = module.ecr_basic.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr_basic.repository_arn
}
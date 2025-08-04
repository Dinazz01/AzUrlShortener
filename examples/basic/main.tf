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

# Basic ECR repository with custom KMS key
module "ecr_basic" {
  source = "../../modules/ecr"

  repository_name = "my-app"

  tags = {
    Environment = "dev"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}

# Output the repository URL for easy reference
output "repository_url" {
  description = "The repository URL"
  value       = module.ecr_basic.repository_url
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = module.ecr_basic.docker_commands.login
  sensitive   = true
}
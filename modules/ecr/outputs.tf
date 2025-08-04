# ECR Repository Outputs
output "repository_arn" {
  description = "Full ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "URL of the ECR repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.this.registry_id
}

# KMS Key Outputs
output "kms_key_id" {
  description = "ID of the KMS key used for ECR encryption"
  value       = var.create_kms_key ? aws_kms_key.ecr[0].key_id : null
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for ECR encryption"
  value       = var.create_kms_key ? aws_kms_key.ecr[0].arn : var.existing_kms_key_arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = var.create_kms_key ? aws_kms_alias.ecr[0].name : null
}

output "kms_key_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = var.create_kms_key ? aws_kms_alias.ecr[0].arn : null
}

# Repository Configuration Outputs
output "image_tag_mutability" {
  description = "Image tag mutability setting for the repository"
  value       = aws_ecr_repository.this.image_tag_mutability
}

output "encryption_configuration" {
  description = "Encryption configuration for the repository"
  value = {
    encryption_type = aws_ecr_repository.this.encryption_configuration[0].encryption_type
    kms_key        = aws_ecr_repository.this.encryption_configuration[0].kms_key
  }
}

output "image_scanning_configuration" {
  description = "Image scanning configuration for the repository"
  value = {
    scan_on_push = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push
  }
}

# Policy Outputs
output "repository_policy" {
  description = "The repository policy applied to the ECR repository"
  value       = var.repository_policy != null ? aws_ecr_repository_policy.this[0].policy : null
}

output "lifecycle_policy" {
  description = "The lifecycle policy applied to the ECR repository"
  value = var.lifecycle_policy != null ? aws_ecr_lifecycle_policy.this[0].policy : (
    var.enable_default_lifecycle_policy ? aws_ecr_lifecycle_policy.default[0].policy : null
  )
}

# Useful Docker Commands
output "docker_commands" {
  description = "Useful Docker commands for this ECR repository"
  value = {
    login = "aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}"
    build_and_tag = "docker build -t ${aws_ecr_repository.this.name}:latest ."
    tag_for_push = "docker tag ${aws_ecr_repository.this.name}:latest ${aws_ecr_repository.this.repository_url}:latest"
    push = "docker push ${aws_ecr_repository.this.repository_url}:latest"
    pull = "docker pull ${aws_ecr_repository.this.repository_url}:latest"
  }
}

# Account and Region Information
output "aws_account_id" {
  description = "AWS account ID where the repository was created"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where the repository was created"
  value       = data.aws_region.current.name
}
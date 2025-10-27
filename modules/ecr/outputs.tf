# ECR Repository Outputs
output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
  value       = aws_ecr_repository.this.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = aws_ecr_repository.this.registry_id
}

# Repository Policy Outputs
output "repository_policy" {
  description = "The repository policy JSON document"
  value       = try(aws_ecr_repository_policy.this[0].policy, null)
}

# Lifecycle Policy Outputs
output "lifecycle_policy" {
  description = "The lifecycle policy JSON document"
  value       = try(coalesce(
    aws_ecr_lifecycle_policy.this[0].policy,
    aws_ecr_lifecycle_policy.default[0].policy
  ), null)
}

# Cross-Account Role Outputs
output "cross_account_role_arn" {
  description = "ARN of the cross-account IAM role"
  value       = try(aws_iam_role.ecr_cross_account[0].arn, null)
}

output "cross_account_role_name" {
  description = "Name of the cross-account IAM role"
  value       = try(aws_iam_role.ecr_cross_account[0].name, null)
}

# Additional Useful Outputs
output "repository_registry_url" {
  description = "The registry URL"
  value       = split("/", aws_ecr_repository.this.repository_url)[0]
}

output "repository_image_tag_mutability" {
  description = "The tag mutability setting for the repository"
  value       = aws_ecr_repository.this.image_tag_mutability
}

output "repository_encryption_configuration" {
  description = "Encryption configuration for the repository"
  value       = aws_ecr_repository.this.encryption_configuration
}

output "repository_image_scanning_configuration" {
  description = "Image scanning configuration for the repository"
  value       = aws_ecr_repository.this.image_scanning_configuration
}

# Pull Through Cache Rules Outputs
output "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  value = {
    for k, v in aws_ecr_pull_through_cache_rule.this : k => {
      ecr_repository_prefix = v.ecr_repository_prefix
      upstream_registry_url = v.upstream_registry_url
      registry_id          = v.registry_id
    }
  }
}
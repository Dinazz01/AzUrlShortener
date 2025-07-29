# Enhanced ECR Security Module Outputs

# Base ECR Outputs (from base module)
output "repository_arn" {
  description = "Full ARN of the repository"
  value       = module.ecr_base.repository_arn
}

output "repository_name" {
  description = "Name of the repository"
  value       = module.ecr_base.repository_name
}

output "repository_url" {
  description = "URL of the repository"
  value       = module.ecr_base.repository_url
}

output "registry_id" {
  description = "Registry ID where the repository was created"
  value       = module.ecr_base.registry_id
}

output "repository_registry_url" {
  description = "The registry URL"
  value       = module.ecr_base.repository_registry_url
}

# VPC Endpoint Outputs
output "vpc_endpoint_ecr_api_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = try(aws_vpc_endpoint.ecr_api[0].id, null)
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = try(aws_vpc_endpoint.ecr_dkr[0].id, null)
}

output "vpc_endpoint_security_group_id" {
  description = "ID of the security group for VPC endpoints"
  value       = try(aws_security_group.ecr_endpoint[0].id, null)
}

# CloudTrail Outputs
output "cloudtrail_arn" {
  description = "ARN of the CloudTrail for ECR logging"
  value       = try(aws_cloudtrail.ecr[0].arn, null)
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail for ECR logging"
  value       = try(aws_cloudtrail.ecr[0].name, null)
}

# CloudWatch Outputs
output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for ECR audit"
  value       = try(aws_cloudwatch_log_group.ecr_audit[0].arn, null)
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for ECR audit"
  value       = try(aws_cloudwatch_log_group.ecr_audit[0].name, null)
}

# Metric Filter Outputs
output "metric_filter_push_name" {
  description = "Name of the CloudWatch metric filter for image pushes"
  value       = try(aws_cloudwatch_log_metric_filter.ecr_push[0].name, null)
}

output "metric_filter_unauthorized_name" {
  description = "Name of the CloudWatch metric filter for unauthorized access"
  value       = try(aws_cloudwatch_log_metric_filter.ecr_unauthorized[0].name, null)
}

# Alarm Outputs
output "security_alarm_arn" {
  description = "ARN of the security CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.ecr_unauthorized_access[0].arn, null)
}

output "cost_alarm_arn" {
  description = "ARN of the cost CloudWatch alarm"
  value       = try(aws_cloudwatch_metric_alarm.ecr_high_storage[0].arn, null)
}

# SNS Outputs
output "security_topic_arn" {
  description = "ARN of the security SNS topic"
  value       = try(aws_sns_topic.security_alerts[0].arn, null)
}

output "security_topic_name" {
  description = "Name of the security SNS topic"
  value       = try(aws_sns_topic.security_alerts[0].name, null)
}

# Image Signing Outputs
output "signing_profile_arn" {
  description = "ARN of the AWS Signer signing profile"
  value       = try(aws_signer_signing_profile.ecr[0].arn, null)
}

output "signing_profile_name" {
  description = "Name of the AWS Signer signing profile"
  value       = try(aws_signer_signing_profile.ecr[0].name, null)
}

# EventBridge Outputs
output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule for ECR events"
  value       = try(aws_cloudwatch_event_rule.ecr_events[0].arn, null)
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule for ECR events"
  value       = try(aws_cloudwatch_event_rule.ecr_events[0].name, null)
}

# Security Configuration Summary
output "security_features_enabled" {
  description = "Summary of enabled security features"
  value = {
    vpc_endpoints        = var.vpc_id != null
    cloudtrail_logging   = var.enable_cloudtrail
    cloudwatch_logs      = var.enable_cloudwatch_logs
    security_alarms      = var.enable_security_alarms
    cost_alarms          = var.enable_cost_alarms
    image_signing        = var.enable_image_signing
    eventbridge_rules    = var.enable_eventbridge
    sns_notifications    = var.create_security_topic || var.existing_sns_topic_arn != null
    enhanced_scanning    = var.enable_registry_scanning
    kms_encryption       = var.encryption_type == "KMS"
    immutable_tags       = var.image_tag_mutability == "IMMUTABLE"
  }
}

# Compliance Information
output "compliance_info" {
  description = "Compliance and security posture information"
  value = {
    encryption_at_rest   = var.encryption_type
    encryption_in_transit = "TLS"
    vulnerability_scanning = var.scan_on_push && var.enable_registry_scanning
    access_logging       = var.enable_cloudtrail
    monitoring_enabled   = var.enable_cloudwatch_logs
    tag_immutability     = var.image_tag_mutability
    lifecycle_management = var.enable_default_lifecycle_policy || var.lifecycle_policy != null
    cross_account_access = var.create_cross_account_role
    network_isolation    = var.vpc_id != null
  }
}
# Enhanced ECR Security Module Variables

# Base ECR Variables (passed through to base module)
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "IMMUTABLE"  # Default to secure setting
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "enable_registry_scanning" {
  description = "Enable enhanced scanning for the registry"
  type        = bool
  default     = true  # Default to secure setting
}

variable "registry_scan_type" {
  description = "The scanning type for the registry. Must be ENHANCED or BASIC"
  type        = string
  default     = "ENHANCED"
}

variable "registry_scan_rules" {
  description = "List of registry scanning rules"
  type = list(object({
    scan_frequency      = string
    repository_filter   = string
    filter_type         = string
  }))
  default = []
}

variable "encryption_type" {
  description = "The encryption type for the repository. Must be one of: AES256 or KMS"
  type        = string
  default     = "KMS"  # Default to secure setting
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use when encryption_type is KMS"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "The policy document for the ECR repository"
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "The policy document for the ECR lifecycle policy"
  type        = string
  default     = null
}

variable "enable_default_lifecycle_policy" {
  description = "Enable default lifecycle policy if no custom policy is provided"
  type        = bool
  default     = true
}

variable "max_image_count" {
  description = "Maximum number of images to keep in the repository (for default lifecycle policy)"
  type        = number
  default     = 10
}

variable "max_image_age_days" {
  description = "Maximum age of images in days (for default lifecycle policy)"
  type        = number
  default     = 30
}

variable "replication_destinations" {
  description = "List of replication destinations"
  type = list(list(object({
    region      = string
    registry_id = string
  })))
  default = []
}

variable "replication_repository_filters" {
  description = "List of repository filters for replication"
  type = list(object({
    filter      = string
    filter_type = string
  }))
  default = []
}

variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  type = map(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
  }))
  default = {}
}

variable "create_cross_account_role" {
  description = "Create IAM role for cross-account access"
  type        = bool
  default     = false
}

variable "cross_account_arns" {
  description = "List of AWS account ARNs that can assume the cross-account role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

# Enhanced Security Variables

# VPC Configuration
variable "vpc_id" {
  description = "VPC ID for creating VPC endpoints"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoints"
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC for security group rules"
  type        = string
  default     = "10.0.0.0/16"
}

# CloudTrail Configuration
variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging for ECR API calls"
  type        = bool
  default     = false
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
  default     = null
}

# CloudWatch Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch logs for ECR audit"
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90
}

# Security Alarms
variable "enable_security_alarms" {
  description = "Enable CloudWatch alarms for security events"
  type        = bool
  default     = false
}

variable "security_alarm_actions" {
  description = "List of ARNs to notify when security alarms are triggered"
  type        = list(string)
  default     = []
}

# Cost Alarms
variable "enable_cost_alarms" {
  description = "Enable CloudWatch alarms for cost monitoring"
  type        = bool
  default     = false
}

variable "cost_alarm_actions" {
  description = "List of ARNs to notify when cost alarms are triggered"
  type        = list(string)
  default     = []
}

variable "storage_threshold_bytes" {
  description = "Storage threshold in bytes for cost alarms"
  type        = number
  default     = 10737418240  # 10GB
}

# SNS Configuration
variable "create_security_topic" {
  description = "Create SNS topic for security notifications"
  type        = bool
  default     = false
}

variable "security_notification_emails" {
  description = "List of email addresses to receive security notifications"
  type        = list(string)
  default     = []
}

variable "existing_sns_topic_arn" {
  description = "ARN of existing SNS topic for notifications"
  type        = string
  default     = null
}

# Image Signing
variable "enable_image_signing" {
  description = "Enable AWS Signer for image signing"
  type        = bool
  default     = false
}

variable "signing_platform_id" {
  description = "Platform ID for AWS Signer"
  type        = string
  default     = "AWSLambda-SHA384-ECDSA"
}

variable "signature_validity_years" {
  description = "Number of years for signature validity"
  type        = number
  default     = 5
}

# EventBridge Configuration
variable "enable_eventbridge" {
  description = "Enable EventBridge rules for ECR events"
  type        = bool
  default     = false
}

variable "enable_event_notifications" {
  description = "Send ECR events to SNS topic"
  type        = bool
  default     = false
}
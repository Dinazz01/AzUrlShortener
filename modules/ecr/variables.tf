# Required Variables
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

# KMS Configuration
variable "create_kms_key" {
  description = "Whether to create a new KMS key for ECR encryption"
  type        = bool
  default     = true
}

variable "kms_key_description" {
  description = "Description for the KMS key. If null, a default description will be used"
  type        = string
  default     = null
}

variable "kms_key_alias" {
  description = "Alias for the KMS key. If null, will default to 'ecr-{repository_name}'"
  type        = string
  default     = null
}

variable "kms_key_deletion_window_in_days" {
  description = "Duration in days after which the key is deleted after destruction of the resource"
  type        = number
  default     = 10
  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "enable_kms_key_rotation" {
  description = "Whether to enable automatic KMS key rotation"
  type        = bool
  default     = true
}

variable "kms_key_multi_region" {
  description = "Whether the KMS key should be multi-region"
  type        = bool
  default     = false
}

variable "kms_key_administrators" {
  description = "List of IAM ARNs for users/roles that can administer the KMS key"
  type        = list(string)
  default     = []
}

variable "kms_key_users" {
  description = "List of IAM ARNs for users/roles that can use the KMS key for encryption/decryption"
  type        = list(string)
  default     = []
}

variable "existing_kms_key_arn" {
  description = "ARN of existing KMS key to use when create_kms_key is false"
  type        = string
  default     = null
}

variable "encryption_type" {
  description = "Encryption type to use when create_kms_key is false. Valid values are AES256, KMS"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

# ECR Repository Configuration
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images"
  type        = bool
  default     = false
}

variable "scan_on_push" {
  description = "Whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

# Repository Policy
variable "repository_policy" {
  description = "JSON policy document for the ECR repository. If null, no policy will be applied"
  type        = string
  default     = null
}

# Lifecycle Policy Configuration
variable "lifecycle_policy" {
  description = "JSON policy document for the ECR lifecycle policy. If null and enable_default_lifecycle_policy is true, a default policy will be created"
  type        = string
  default     = null
}

variable "enable_default_lifecycle_policy" {
  description = "Whether to create a default lifecycle policy when lifecycle_policy is null"
  type        = bool
  default     = true
}

variable "lifecycle_policy_max_image_count" {
  description = "Maximum number of tagged images to keep (used in default lifecycle policy)"
  type        = number
  default     = 10
  validation {
    condition     = var.lifecycle_policy_max_image_count > 0
    error_message = "Maximum image count must be greater than 0."
  }
}

variable "lifecycle_policy_untagged_days" {
  description = "Number of days to keep untagged images (used in default lifecycle policy)"
  type        = number
  default     = 1
  validation {
    condition     = var.lifecycle_policy_untagged_days > 0
    error_message = "Untagged image retention days must be greater than 0."
  }
}

# Tags
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}
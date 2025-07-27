# Required Variables
variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

# ECR Repository Configuration
variable "image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "force_delete" {
  description = "If true, will delete the repository even if it contains images"
  type        = bool
  default     = false
}

# Image Scanning Configuration
variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "enable_registry_scanning" {
  description = "Enable enhanced scanning for the registry"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "The scanning type for the registry. Must be ENHANCED or BASIC"
  type        = string
  default     = "ENHANCED"
  validation {
    condition     = contains(["ENHANCED", "BASIC"], var.registry_scan_type)
    error_message = "registry_scan_type must be either ENHANCED or BASIC."
  }
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

# Encryption Configuration
variable "encryption_type" {
  description = "The encryption type for the repository. Must be one of: AES256 or KMS"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }
}

variable "kms_key_id" {
  description = "The ARN of the KMS key to use when encryption_type is KMS"
  type        = string
  default     = null
}

# Repository Policy
variable "repository_policy" {
  description = "The policy document for the ECR repository"
  type        = string
  default     = null
}

# Lifecycle Policy Configuration
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

# Replication Configuration
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

# Pull Through Cache Configuration
variable "pull_through_cache_rules" {
  description = "Map of pull through cache rules"
  type = map(object({
    ecr_repository_prefix = string
    upstream_registry_url = string
    credential_arn        = optional(string)
  }))
  default = {}
}

# Cross-Account Access Configuration
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

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
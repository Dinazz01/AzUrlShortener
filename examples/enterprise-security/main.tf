# Enterprise Security ECR Example
# This example demonstrates a complete enterprise-grade ECR setup with all security features

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

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC for secure networking
resource "aws_vpc" "ecr" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ecr-enterprise-vpc"
  }
}

# Private subnets for VPC endpoints
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.ecr.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "ecr-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ecr" {
  vpc_id = aws_vpc.ecr.id

  tags = {
    Name = "ecr-enterprise-igw"
  }
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ecr.id

  tags = {
    Name = "ecr-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "ECR encryption key for enterprise repository"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR Service"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "ECR-Enterprise-Encryption-Key"
    Environment = "production"
  }
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-enterprise-encryption"
  target_key_id = aws_kms_key.ecr.key_id
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${data.aws_caller_identity.current.account_id}-ecr-cloudtrail-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ECR-CloudTrail-Logs"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Enterprise ECR Repository with full security features
module "ecr_enterprise" {
  source = "../../modules/ecr-security"

  repository_name      = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  encryption_type     = "KMS"
  kms_key_id          = aws_kms_key.ecr.arn

  # Enhanced scanning
  enable_registry_scanning = true
  registry_scan_type      = "ENHANCED"
  
  registry_scan_rules = [
    {
      scan_frequency     = "SCAN_ON_PUSH"
      repository_filter  = var.repository_name
      filter_type        = "WILDCARD"
    },
    {
      scan_frequency     = "CONTINUOUS_SCAN"
      repository_filter  = var.repository_name
      filter_type        = "WILDCARD"
    }
  ]

  # Strict lifecycle policy for production
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release-", "prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep staging images for 7 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["staging-", "dev-"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
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

  # Repository policy with strict access control
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAnonymousAccess"
        Effect = "Deny"
        Principal = "*"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalType" = ["User", "AssumedRole"]
          }
        }
      },
      {
        Sid    = "AllowProductionAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.production_role_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      },
      {
        Sid    = "AllowPushFromCI"
        Effect = "Allow"
        Principal = {
          AWS = var.ci_role_arns
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })

  # Cross-region replication for DR
  replication_destinations = [
    [
      {
        region      = var.dr_region
        registry_id = data.aws_caller_identity.current.account_id
      }
    ]
  ]

  # Pull-through cache for public images
  pull_through_cache_rules = {
    dockerhub = {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
    }
    public_ecr = {
      ecr_repository_prefix = "public"
      upstream_registry_url = "public.ecr.aws"
    }
  }

  # VPC configuration for private endpoints
  vpc_id             = aws_vpc.ecr.id
  private_subnet_ids = aws_subnet.private[*].id
  vpc_cidr           = aws_vpc.ecr.cidr_block

  # CloudTrail logging
  enable_cloudtrail       = true
  cloudtrail_bucket_name  = aws_s3_bucket.cloudtrail.bucket

  # CloudWatch monitoring
  enable_cloudwatch_logs        = true
  cloudwatch_log_retention_days = 365  # 1 year retention for compliance

  # Security and cost alarms
  enable_security_alarms = true
  enable_cost_alarms     = true
  storage_threshold_bytes = 5368709120  # 5GB threshold

  # SNS notifications
  create_security_topic        = true
  security_notification_emails = var.security_notification_emails

  # EventBridge for real-time monitoring
  enable_eventbridge        = true
  enable_event_notifications = true

  # Image signing for integrity
  enable_image_signing       = true
  signing_platform_id        = "AWSLambda-SHA384-ECDSA"
  signature_validity_years   = 5

  tags = {
    Environment   = "production"
    Security      = "enterprise"
    Compliance    = "required"
    Team          = "platform"
    Application   = var.repository_name
    BackupPolicy  = "required"
    DataClass     = "confidential"
  }
}

# Additional SNS topic for cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.repository_name}-cost-alerts"

  tags = {
    Name = "${var.repository_name}-cost-alerts"
  }
}

resource "aws_sns_topic_subscription" "cost_email" {
  count = length(var.cost_notification_emails)

  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.cost_notification_emails[count.index]
}

# Custom CloudWatch dashboard for monitoring
resource "aws_cloudwatch_dashboard" "ecr" {
  dashboard_name = "${var.repository_name}-ecr-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECR", "RepositorySizeInBytes", "RepositoryName", var.repository_name],
            [".", "RepositoryPullCount", ".", "."],
            [".", "RepositoryPushCount", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ECR Repository Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/ecr/${var.repository_name}/audit' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = data.aws_region.current.name
          title   = "Recent ECR Events"
        }
      }
    ]
  })
}

# Outputs
output "repository_url" {
  description = "ECR repository URL"
  value       = module.ecr_enterprise.repository_url
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr_enterprise.repository_arn
}

output "security_features_enabled" {
  description = "Summary of enabled security features"
  value       = module.ecr_enterprise.security_features_enabled
}

output "compliance_info" {
  description = "Compliance and security posture"
  value       = module.ecr_enterprise.compliance_info
}

output "vpc_endpoint_api_id" {
  description = "VPC endpoint ID for ECR API"
  value       = module.ecr_enterprise.vpc_endpoint_ecr_api_id
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN for ECR logging"
  value       = module.ecr_enterprise.cloudtrail_arn
}

output "signing_profile_arn" {
  description = "AWS Signer profile ARN"
  value       = module.ecr_enterprise.signing_profile_arn
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.ecr.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.ecr.dashboard_name}"
}
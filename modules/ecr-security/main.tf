# Enhanced ECR Security Module
# This module includes additional security features like VPC endpoints, monitoring, and compliance

# ECR Repository (using the base module)
module "ecr_base" {
  source = "../ecr"

  repository_name               = var.repository_name
  image_tag_mutability         = var.image_tag_mutability
  force_delete                 = var.force_delete
  scan_on_push                 = var.scan_on_push
  enable_registry_scanning     = var.enable_registry_scanning
  registry_scan_type           = var.registry_scan_type
  registry_scan_rules          = var.registry_scan_rules
  encryption_type              = var.encryption_type
  kms_key_id                   = var.kms_key_id
  repository_policy            = var.repository_policy
  lifecycle_policy             = var.lifecycle_policy
  enable_default_lifecycle_policy = var.enable_default_lifecycle_policy
  max_image_count              = var.max_image_count
  max_image_age_days           = var.max_image_age_days
  replication_destinations     = var.replication_destinations
  replication_repository_filters = var.replication_repository_filters
  pull_through_cache_rules     = var.pull_through_cache_rules
  create_cross_account_role    = var.create_cross_account_role
  cross_account_arns           = var.cross_account_arns
  tags                         = var.tags
}

# VPC Endpoints for ECR (if VPC is provided)
resource "aws_vpc_endpoint" "ecr_api" {
  count = var.vpc_id != null ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ecr_endpoint[0].id]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-ecr-api-endpoint"
      Type = "ECR-API"
    }
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.vpc_id != null ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ecr_endpoint[0].id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-ecr-dkr-endpoint"
      Type = "ECR-DKR"
    }
  )
}

# Security Group for ECR VPC Endpoints
resource "aws_security_group" "ecr_endpoint" {
  count = var.vpc_id != null ? 1 : 0

  name_prefix = "${var.repository_name}-ecr-endpoint-"
  vpc_id      = var.vpc_id
  description = "Security group for ECR VPC endpoints"

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-ecr-endpoint-sg"
    }
  )
}

# CloudTrail for ECR API logging
resource "aws_cloudtrail" "ecr" {
  count = var.enable_cloudtrail ? 1 : 0

  name           = "${var.repository_name}-ecr-trail"
  s3_bucket_name = var.cloudtrail_bucket_name

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::ECR::Repository"
      values = [module.ecr_base.repository_arn]
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-ecr-trail"
    }
  )
}

# CloudWatch Log Group for ECR audit logs
resource "aws_cloudwatch_log_group" "ecr_audit" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/ecr/${var.repository_name}/audit"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-ecr-audit-logs"
    }
  )
}

# CloudWatch Metric Filters
resource "aws_cloudwatch_log_metric_filter" "ecr_push" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name           = "${var.repository_name}-ecr-image-push"
  log_group_name = aws_cloudwatch_log_group.ecr_audit[0].name
  pattern        = "[timestamp, request_id, event_name=\"PutImage\", ...]"

  metric_transformation {
    name      = "ECRImagePushCount"
    namespace = "ECR/Security"
    value     = "1"
    default_value = "0"
    
    dimensions = {
      RepositoryName = var.repository_name
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "ecr_unauthorized" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name           = "${var.repository_name}-ecr-unauthorized-access"
  log_group_name = aws_cloudwatch_log_group.ecr_audit[0].name
  pattern        = "[timestamp, request_id, event_name, error_code=\"UnauthorizedOperation\", ...]"

  metric_transformation {
    name      = "ECRUnauthorizedAccess"
    namespace = "ECR/Security"
    value     = "1"
    default_value = "0"
    
    dimensions = {
      RepositoryName = var.repository_name
    }
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "ecr_unauthorized_access" {
  count = var.enable_security_alarms ? 1 : 0

  alarm_name          = "${var.repository_name}-ecr-unauthorized-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ECRUnauthorizedAccess"
  namespace           = "ECR/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Unauthorized access attempts to ECR repository ${var.repository_name}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RepositoryName = var.repository_name
  }

  alarm_actions = var.security_alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "ecr_high_storage" {
  count = var.enable_cost_alarms ? 1 : 0

  alarm_name          = "${var.repository_name}-ecr-high-storage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RepositorySizeInBytes"
  namespace           = "AWS/ECR"
  period              = "86400"  # 24 hours
  statistic           = "Average"
  threshold           = var.storage_threshold_bytes
  alarm_description   = "ECR repository ${var.repository_name} size exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RepositoryName = var.repository_name
  }

  alarm_actions = var.cost_alarm_actions
}

# SNS Topic for Security Alerts (if not provided)
resource "aws_sns_topic" "security_alerts" {
  count = var.create_security_topic ? 1 : 0
  name  = "${var.repository_name}-ecr-security-alerts"

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-security-alerts"
    }
  )
}

resource "aws_sns_topic_subscription" "security_email" {
  count = var.create_security_topic && length(var.security_notification_emails) > 0 ? length(var.security_notification_emails) : 0

  topic_arn = aws_sns_topic.security_alerts[0].arn
  protocol  = "email"
  endpoint  = var.security_notification_emails[count.index]
}

# Image Signing Profile (AWS Signer)
resource "aws_signer_signing_profile" "ecr" {
  count = var.enable_image_signing ? 1 : 0

  platform_id = var.signing_platform_id
  name        = "${var.repository_name}-signing-profile"

  signature_validity_period {
    value = var.signature_validity_years
    type  = "YEARS"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.repository_name}-signing-profile"
    }
  )
}

# EventBridge Rule for ECR Events
resource "aws_cloudwatch_event_rule" "ecr_events" {
  count = var.enable_eventbridge ? 1 : 0

  name        = "${var.repository_name}-ecr-events"
  description = "Capture ECR events for repository ${var.repository_name}"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      repository-name = [var.repository_name]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.enable_eventbridge && var.enable_event_notifications ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecr_events[0].name
  target_id = "SendToSNS"
  arn       = var.create_security_topic ? aws_sns_topic.security_alerts[0].arn : var.existing_sns_topic_arn
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
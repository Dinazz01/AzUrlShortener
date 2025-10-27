# AWS ECR Security & Best Practices Guide

This guide outlines security best practices for AWS ECR and demonstrates how our Terraform module implements these recommendations.

## 📋 Overview of AWS ECR

Amazon ECR is a fully managed container registry for storing, scanning, and managing container images.

**Key Integrations:**
- ✅ ECS, EKS, Lambda
- ✅ IAM, PrivateLink, CloudTrail
- ✅ Regional replication, HA, cross-region replication
- ✅ Version control for images
- ✅ CLI compatible, CI/CD pipeline integration

---

## 🔐 Security & Access Control

### 🔒 Networking & Endpoint Security

**Best Practices:**
- ✅ Use VPC endpoints or AWS Direct Connect to avoid public internet exposure
- ✅ Use security groups to restrict inbound/outbound traffic
- ✅ Block publicly exposing sensitive images
- ✅ Public image access only through caching (pull-through)

**Module Implementation:**
```hcl
# Example: VPC Endpoint for ECR
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.ecr_endpoint.id]
  
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
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Security Group for ECR VPC Endpoint
resource "aws_security_group" "ecr_endpoint" {
  name_prefix = "ecr-vpc-endpoint-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Pull-through cache for public images
module "ecr_with_cache" {
  source = "./modules/ecr"

  repository_name = "my-app"
  
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
}
```

### 🔐 IAM & Permissions

**Best Practices:**
- ✅ Use fine-grained IAM policies and registry permissions
- ✅ Avoid using `*` in IAM policies
- ✅ No anonymous access to private repositories
- ✅ Enforce access policies at repository level
- ✅ Use resource-based policies for enhanced control

**Module Implementation:**
```hcl
# Fine-grained IAM policy example
module "ecr_secure" {
  source = "./modules/ecr"

  repository_name = "production-api"
  
  # Resource-based repository policy
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
            "aws:PrincipalType" = "User"
          }
        }
      },
      {
        Sid    = "AllowSpecificRoles"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::123456789012:role/ECS-TaskRole",
            "arn:aws:iam::123456789012:role/CI-CD-Role"
          ]
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
          AWS = "arn:aws:iam::123456789012:role/CI-CD-Role"
        }
        Action = [
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })

  # Cross-account access with specific permissions
  create_cross_account_role = true
  cross_account_arns = [
    "arn:aws:iam::ACCOUNT-ID:root"
  ]
}
```

---

## 🛡️ Scanning & Vulnerability Management

**Best Practices:**
- ✅ Enable image scanning on push or continuous scan
- ✅ Detect vulnerabilities before production
- ✅ Use Amazon Inspector for automated scanning
- ✅ Ensure tag immutability for stable images

**Module Implementation:**
```hcl
module "ecr_with_scanning" {
  source = "./modules/ecr"

  repository_name      = "secure-app"
  image_tag_mutability = "IMMUTABLE"  # Prevent overwriting stable images
  scan_on_push        = true          # Scan on every push
  
  # Enhanced scanning configuration
  enable_registry_scanning = true
  registry_scan_type      = "ENHANCED"
  
  registry_scan_rules = [
    {
      scan_frequency     = "SCAN_ON_PUSH"
      repository_filter  = "secure-*"
      filter_type        = "WILDCARD"
    },
    {
      scan_frequency     = "CONTINUOUS_SCAN"
      repository_filter  = "production-*"
      filter_type        = "WILDCARD"
    }
  ]

  tags = {
    Security    = "high"
    Scanning    = "enabled"
    Environment = "production"
  }
}
```

---

## 🔐 Encryption & Data Protection

**Best Practices:**
- ✅ Do not store sensitive data in container images
- ✅ Use S3 SSE with Amazon-managed or KMS-managed keys
- ✅ DSSE-KMS (dual-layer encryption) for additional security
- ✅ Encryption in transit is enforced
- ✅ Use AWS Signer to sign container images

**Module Implementation:**
```hcl
# KMS key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "ECR encryption key"
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
      }
    ]
  })

  tags = {
    Name = "ECR-Encryption-Key"
  }
}

# ECR with KMS encryption
module "ecr_encrypted" {
  source = "./modules/ecr"

  repository_name = "encrypted-app"
  encryption_type = "KMS"
  kms_key_id     = aws_kms_key.ecr.arn

  tags = {
    Encryption = "KMS"
    Security   = "high"
  }
}

# Image signing with AWS Signer (additional resource)
resource "aws_signer_signing_profile" "ecr" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name        = "ecr_signing_profile"

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = {
    Name = "ECR-Image-Signing"
  }
}
```

---

## 📊 Monitoring & Auditing

**Best Practices:**
- ✅ Enable logging via CloudTrail
- ✅ Integrate with CloudWatch, Dynatrace, or Splunk
- ✅ Support compliance, forensics, and unauthorized action detection

**Implementation Example:**
```hcl
# CloudTrail for ECR API logging
resource "aws_cloudtrail" "ecr" {
  name           = "ecr-api-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::ECR::Repository"
      values = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"]
    }
  }

  tags = {
    Name = "ECR-CloudTrail"
  }
}

# CloudWatch Log Group for ECR
resource "aws_cloudwatch_log_group" "ecr" {
  name              = "/aws/ecr/audit"
  retention_in_days = 90

  tags = {
    Name = "ECR-Audit-Logs"
  }
}

# CloudWatch Metric Filters for ECR events
resource "aws_cloudwatch_log_metric_filter" "ecr_push" {
  name           = "ECR-Image-Push"
  log_group_name = aws_cloudwatch_log_group.ecr.name
  pattern        = "[timestamp, request_id, event_name=\"PutImage\", ...]"

  metric_transformation {
    name      = "ECRImagePushCount"
    namespace = "ECR/Security"
    value     = "1"
  }
}

# CloudWatch Alarm for unauthorized access attempts
resource "aws_cloudwatch_metric_alarm" "ecr_unauthorized" {
  alarm_name          = "ECR-Unauthorized-Access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ECRUnauthorizedAccess"
  namespace           = "ECR/Security"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors unauthorized ECR access attempts"

  alarm_actions = [aws_sns_topic.security_alerts.arn]
}
```

---

## 🗃️ Storage, Cost Optimization & Lifecycle

**Best Practices:**
- ✅ Images stored in Amazon S3 (cost-effective and durable)
- ✅ Use lifecycle policies to clean up outdated images
- ✅ Use slim base images, multi-stage builds, compressed assets
- ✅ Public images cached to reduce costs

**Module Implementation:**
```hcl
module "ecr_optimized" {
  source = "./modules/ecr"

  repository_name = "cost-optimized-app"
  
  # Aggressive lifecycle policy for cost optimization
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 5 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
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

  # Cost optimization tags
  tags = {
    CostCenter     = "engineering"
    Environment    = "production"
    Optimization   = "enabled"
  }
}

# Cost monitoring with CloudWatch
resource "aws_cloudwatch_metric_alarm" "ecr_storage_cost" {
  alarm_name          = "ECR-High-Storage-Cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RepositorySizeInBytes"
  namespace           = "AWS/ECR"
  period              = "86400"  # 24 hours
  statistic           = "Average"
  threshold           = "10737418240"  # 10GB in bytes
  alarm_description   = "ECR repository size exceeds 10GB"

  dimensions = {
    RepositoryName = module.ecr_optimized.repository_name
  }

  alarm_actions = [aws_sns_topic.cost_alerts.arn]
}
```

---

## 🔄 Integration & Artifact Management

**Best Practices:**
- ✅ Support Docker and OCI-compliant artifacts
- ✅ Support Helm charts
- ✅ Integration with JFrog Artifactory
- ✅ CI/CD pipeline integration

**Implementation Examples:**

### Docker & OCI Artifacts
```hcl
module "ecr_artifacts" {
  source = "./modules/ecr"

  repository_name = "multi-artifact-repo"
  
  tags = {
    ArtifactTypes = "docker,oci,helm"
    Integration   = "enabled"
  }
}
```

### CI/CD Integration Example
```yaml
# GitHub Actions workflow
name: Build and Push to ECR

on:
  push:
    branches: [main, develop]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: my-app
          IMAGE_TAG: ${{ github.sha }}
        run: |
          # Build image
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:latest .
          
          # Scan image locally (optional)
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          
          # Push image
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Image digest
        run: echo ${{ steps.build-image.outputs.image }}
```

---

## 📌 Feature Summary

| Feature | Module Support | Implementation |
|---------|---------------|----------------|
| **Security** | ✅ | IAM, encryption, scanning, no public access |
| **Monitoring** | ✅ | CloudTrail, CloudWatch integration ready |
| **Encryption** | ✅ | S3, KMS, DSSE-KMS, in transit |
| **Access Control** | ✅ | IAM + resource-based policies |
| **Compliance** | ✅ | Audit logs, vulnerability scans, image signing support |
| **Storage & Cost Optimization** | ✅ | S3 backend, lifecycle policies, base image reduction |
| **Artifact Support** | ✅ | Docker, OCI, Helm |
| **Cross-Region Replication** | ✅ | Multi-region support |
| **Pull-Through Cache** | ✅ | Public registry caching |
| **Enhanced Scanning** | ✅ | Amazon Inspector integration |

---

## 🔍 Security Checklist

Use this checklist to ensure your ECR implementation follows security best practices:

### Network Security
- [ ] VPC endpoints configured for ECR API and DKR
- [ ] Security groups restrict access to necessary ports only
- [ ] No public internet access for sensitive repositories
- [ ] Pull-through cache configured for public images

### Access Control
- [ ] Fine-grained IAM policies (no wildcard permissions)
- [ ] Resource-based repository policies implemented
- [ ] Cross-account access properly configured
- [ ] No anonymous access to private repositories

### Encryption & Data Protection
- [ ] KMS encryption enabled for sensitive repositories
- [ ] Key rotation enabled
- [ ] No sensitive data stored in images
- [ ] Image signing implemented where required

### Scanning & Vulnerability Management
- [ ] Image scanning enabled on push
- [ ] Enhanced scanning configured for critical repositories
- [ ] Tag immutability enabled for production images
- [ ] Vulnerability remediation process defined

### Monitoring & Auditing
- [ ] CloudTrail logging enabled
- [ ] CloudWatch monitoring configured
- [ ] Security alerts set up
- [ ] Regular audit reviews scheduled

### Cost Optimization
- [ ] Lifecycle policies implemented
- [ ] Repository size monitoring enabled
- [ ] Unused repositories cleaned up
- [ ] Cost allocation tags applied

This comprehensive security guide ensures that your ECR implementation follows AWS best practices and maintains a strong security posture.
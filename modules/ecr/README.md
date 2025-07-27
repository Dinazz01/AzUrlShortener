# AWS ECR Terraform Module

This Terraform module creates and manages Amazon Elastic Container Registry (ECR) repositories with comprehensive configuration options including lifecycle policies, image scanning, replication, and security features.

## Features

- ✅ ECR Repository creation with configurable settings
- ✅ Image scanning configuration (basic and enhanced)
- ✅ Lifecycle policies (custom or default)
- ✅ Repository policies for access control
- ✅ Cross-region replication
- ✅ Pull-through cache rules
- ✅ Encryption at rest (AES256 or KMS)
- ✅ Cross-account access with IAM roles
- ✅ Registry-level scanning configuration
- ✅ Comprehensive tagging support

## Usage

### Basic Usage

```hcl
module "ecr_repository" {
  source = "./modules/ecr"

  repository_name = "my-app"
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### Advanced Usage

```hcl
module "ecr_repository" {
  source = "./modules/ecr"

  repository_name      = "my-microservice"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  encryption_type     = "KMS"
  kms_key_id          = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  
  # Custom lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["prod-"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  # Cross-account access
  create_cross_account_role = true
  cross_account_arns = [
    "arn:aws:iam::123456789012:root",
    "arn:aws:iam::123456789013:root"
  ]

  # Replication configuration
  replication_destinations = [
    [
      {
        region      = "us-east-1"
        registry_id = "123456789012"
      },
      {
        region      = "eu-west-1"
        registry_id = "123456789012"
      }
    ]
  ]

  # Pull through cache rules
  pull_through_cache_rules = {
    dockerhub = {
      ecr_repository_prefix = "dockerhub"
      upstream_registry_url = "registry-1.docker.io"
    }
    quay = {
      ecr_repository_prefix = "quay"
      upstream_registry_url = "quay.io"
    }
  }

  tags = {
    Environment = "production"
    Team        = "backend"
    Application = "my-microservice"
  }
}
```

### Multiple Repositories

```hcl
locals {
  repositories = {
    frontend = {
      repository_name      = "frontend-app"
      image_tag_mutability = "MUTABLE"
      max_image_count      = 15
    }
    backend = {
      repository_name      = "backend-api"
      image_tag_mutability = "IMMUTABLE"
      max_image_count      = 25
      max_image_age_days   = 60
    }
    worker = {
      repository_name    = "background-worker"
      scan_on_push      = false
      max_image_count   = 5
    }
  }
}

module "ecr_repositories" {
  source = "./modules/ecr"
  
  for_each = local.repositories

  repository_name      = each.value.repository_name
  image_tag_mutability = try(each.value.image_tag_mutability, "MUTABLE")
  scan_on_push        = try(each.value.scan_on_push, true)
  max_image_count     = try(each.value.max_image_count, 10)
  max_image_age_days  = try(each.value.max_image_age_days, 30)

  tags = {
    Environment = "production"
    Service     = each.key
  }
}
```

### Repository with Enhanced Scanning

```hcl
module "ecr_repository_enhanced" {
  source = "./modules/ecr"

  repository_name           = "secure-app"
  enable_registry_scanning  = true
  registry_scan_type       = "ENHANCED"
  
  registry_scan_rules = [
    {
      scan_frequency     = "SCAN_ON_PUSH"
      repository_filter  = "secure-*"
      filter_type        = "WILDCARD"
    }
  ]

  tags = {
    Security    = "high"
    Compliance  = "required"
  }
}
```

## Examples

See the [examples](./examples) directory for complete working examples:

- [Basic ECR Repository](./examples/basic)
- [ECR with Enhanced Security](./examples/enhanced-security)
- [Multi-Repository Setup](./examples/multi-repository)
- [Cross-Account Access](./examples/cross-account)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| image_tag_mutability | The tag mutability setting for the repository. Must be one of: MUTABLE or IMMUTABLE | `string` | `"MUTABLE"` | no |
| force_delete | If true, will delete the repository even if it contains images | `bool` | `false` | no |
| scan_on_push | Indicates whether images are scanned after being pushed to the repository | `bool` | `true` | no |
| enable_registry_scanning | Enable enhanced scanning for the registry | `bool` | `false` | no |
| registry_scan_type | The scanning type for the registry. Must be ENHANCED or BASIC | `string` | `"ENHANCED"` | no |
| registry_scan_rules | List of registry scanning rules | `list(object({...}))` | `[]` | no |
| encryption_type | The encryption type for the repository. Must be one of: AES256 or KMS | `string` | `"AES256"` | no |
| kms_key_id | The ARN of the KMS key to use when encryption_type is KMS | `string` | `null` | no |
| repository_policy | The policy document for the ECR repository | `string` | `null` | no |
| lifecycle_policy | The policy document for the ECR lifecycle policy | `string` | `null` | no |
| enable_default_lifecycle_policy | Enable default lifecycle policy if no custom policy is provided | `bool` | `true` | no |
| max_image_count | Maximum number of images to keep in the repository (for default lifecycle policy) | `number` | `10` | no |
| max_image_age_days | Maximum age of images in days (for default lifecycle policy) | `number` | `30` | no |
| replication_destinations | List of replication destinations | `list(list(object({...})))` | `[]` | no |
| replication_repository_filters | List of repository filters for replication | `list(object({...}))` | `[]` | no |
| pull_through_cache_rules | Map of pull through cache rules | `map(object({...}))` | `{}` | no |
| create_cross_account_role | Create IAM role for cross-account access | `bool` | `false` | no |
| cross_account_arns | List of AWS account ARNs that can assume the cross-account role | `list(string)` | `[]` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | Full ARN of the repository |
| repository_name | Name of the repository |
| repository_url | URL of the repository |
| registry_id | Registry ID where the repository was created |
| repository_policy | The repository policy JSON document |
| lifecycle_policy | The lifecycle policy JSON document |
| cross_account_role_arn | ARN of the cross-account IAM role |
| cross_account_role_name | Name of the cross-account IAM role |
| repository_registry_url | The registry URL |
| repository_image_tag_mutability | The tag mutability setting for the repository |
| repository_encryption_configuration | Encryption configuration for the repository |
| repository_image_scanning_configuration | Image scanning configuration for the repository |
| pull_through_cache_rules | Map of pull through cache rules |

## Best Practices

### Security
- Enable image scanning (`scan_on_push = true`)
- Use KMS encryption for sensitive applications
- Implement proper IAM policies for repository access
- Use immutable tags for production images (`image_tag_mutability = "IMMUTABLE"`)

### Cost Optimization
- Configure lifecycle policies to automatically clean up old images
- Use appropriate image retention periods
- Monitor repository sizes and costs

### Operational Excellence
- Use consistent naming conventions
- Tag all resources appropriately
- Implement cross-region replication for critical applications
- Use pull-through cache for frequently used public images

### Example Repository Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ECRRole"
      },
      "Action": [
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
}
```

### Example Lifecycle Policy

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 production images",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["prod"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Delete untagged images older than 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Common Use Cases

1. **Development Environment**: Use mutable tags with relaxed lifecycle policies
2. **Production Environment**: Use immutable tags with strict lifecycle policies
3. **Multi-Account Setup**: Configure cross-account access roles
4. **Multi-Region Deployment**: Set up replication to required regions
5. **Security Compliance**: Enable enhanced scanning and encryption

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This module is licensed under the MIT License. See LICENSE file for details.

## Support

For questions, issues, or contributions, please refer to the project's GitHub repository.
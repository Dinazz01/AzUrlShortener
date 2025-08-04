# AWS ECR Terraform Module with Custom KMS Encryption

A comprehensive, reusable Terraform module for creating Amazon Elastic Container Registry (ECR) repositories with custom KMS encryption keys. This module provides enterprise-grade features including fine-grained access control, lifecycle policies, and comprehensive security configurations.

## ✨ Features

- **🔐 Custom KMS Encryption**: Create dedicated KMS keys with proper IAM policies for ECR encryption
- **🔄 Flexible KMS Options**: Use custom KMS keys or existing ones, with fallback to AES256
- **📋 Lifecycle Management**: Built-in intelligent lifecycle policies to manage image retention
- **🛡️ Security Focused**: Image scanning, repository policies, and immutable tag options
- **🏷️ Comprehensive Tagging**: Consistent tagging strategy across all resources
- **📊 Rich Outputs**: Detailed outputs including Docker commands for easy integration
- **✅ Validation**: Input validation to prevent misconfigurations
- **📚 Well Documented**: Comprehensive examples and documentation

## 📋 Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## 🚀 Quick Start

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_name = "my-app"
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## 📖 Usage Examples

### Basic Usage

```hcl
module "ecr_basic" {
  source = "./modules/ecr"

  repository_name = "my-app"

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Advanced Configuration

```hcl
module "ecr_advanced" {
  source = "./modules/ecr"

  repository_name      = "my-production-app"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true

  # KMS Configuration
  kms_key_description            = "KMS key for production ECR"
  kms_key_alias                  = "ecr-production-key"
  kms_key_deletion_window_in_days = 30
  enable_kms_key_rotation        = true
  
  # KMS Permissions
  kms_key_administrators = [
    "arn:aws:iam::123456789012:role/AdminRole"
  ]
  kms_key_users = [
    "arn:aws:iam::123456789012:role/ECSTaskRole"
  ]

  # Custom Repository Policy
  repository_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789012:role/AppRole"
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
    }]
  })

  # Custom Lifecycle Policy
  lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus     = "tagged"
        countType     = "imageCountMoreThan"
        countNumber   = 10
      }
      action = {
        type = "expire"
      }
    }]
  })

  tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### Using Existing KMS Key

```hcl
module "ecr_existing_kms" {
  source = "./modules/ecr"

  repository_name = "my-app"
  
  # Use existing KMS key
  create_kms_key       = false
  encryption_type      = "KMS"
  existing_kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "staging"
  }
}
```

## 📥 Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| repository_name | Name of the ECR repository | `string` | n/a | yes |
| create_kms_key | Whether to create a new KMS key for ECR encryption | `bool` | `true` | no |
| kms_key_description | Description for the KMS key | `string` | `null` | no |
| kms_key_alias | Alias for the KMS key | `string` | `null` | no |
| kms_key_deletion_window_in_days | Duration in days after which the key is deleted after destruction | `number` | `10` | no |
| enable_kms_key_rotation | Whether to enable automatic KMS key rotation | `bool` | `true` | no |
| kms_key_multi_region | Whether the KMS key should be multi-region | `bool` | `false` | no |
| kms_key_administrators | List of IAM ARNs for users/roles that can administer the KMS key | `list(string)` | `[]` | no |
| kms_key_users | List of IAM ARNs for users/roles that can use the KMS key | `list(string)` | `[]` | no |
| existing_kms_key_arn | ARN of existing KMS key to use when create_kms_key is false | `string` | `null` | no |
| encryption_type | Encryption type to use when create_kms_key is false | `string` | `"AES256"` | no |
| image_tag_mutability | The tag mutability setting for the repository | `string` | `"MUTABLE"` | no |
| force_delete | If true, will delete the repository even if it contains images | `bool` | `false` | no |
| scan_on_push | Whether images are scanned after being pushed to the repository | `bool` | `true` | no |
| repository_policy | JSON policy document for the ECR repository | `string` | `null` | no |
| lifecycle_policy | JSON policy document for the ECR lifecycle policy | `string` | `null` | no |
| enable_default_lifecycle_policy | Whether to create a default lifecycle policy | `bool` | `true` | no |
| lifecycle_policy_max_image_count | Maximum number of tagged images to keep | `number` | `10` | no |
| lifecycle_policy_untagged_days | Number of days to keep untagged images | `number` | `1` | no |
| tags | A map of tags to assign to all resources | `map(string)` | `{}` | no |

## 📤 Outputs

| Name | Description |
|------|-------------|
| repository_arn | Full ARN of the ECR repository |
| repository_name | Name of the ECR repository |
| repository_url | URL of the ECR repository |
| registry_id | Registry ID where the repository was created |
| kms_key_id | ID of the KMS key used for ECR encryption |
| kms_key_arn | ARN of the KMS key used for ECR encryption |
| kms_key_alias | Alias of the KMS key |
| kms_key_alias_arn | ARN of the KMS key alias |
| encryption_configuration | Encryption configuration for the repository |
| image_scanning_configuration | Image scanning configuration for the repository |
| docker_commands | Useful Docker commands for this ECR repository |
| aws_account_id | AWS account ID where the repository was created |
| aws_region | AWS region where the repository was created |

## 🐋 Docker Commands

The module outputs helpful Docker commands for working with your ECR repository:

```bash
# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

# Build and tag your image
docker build -t my-app:latest .

# Tag for ECR
docker tag my-app:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest

# Push to ECR
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest

# Pull from ECR
docker pull 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
```

## 🔒 Security Features

### KMS Encryption
- **Custom KMS Keys**: Creates dedicated KMS keys with proper IAM policies
- **Key Rotation**: Automatic annual key rotation for enhanced security
- **Multi-Region Support**: Optional multi-region keys for cross-region replication
- **Fine-grained Permissions**: Separate administrators and users with appropriate permissions

### Repository Security
- **Image Scanning**: Automatic vulnerability scanning on push
- **Immutable Tags**: Support for immutable image tags to prevent overwrites
- **Repository Policies**: Fine-grained access control with custom IAM policies
- **Lifecycle Policies**: Automatic cleanup of old images to reduce attack surface

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   KMS Key       │    │   ECR Repo      │    │  Lifecycle      │
│                 │    │                 │    │  Policy         │
│ • Custom Key    │────│ • Encrypted     │────│ • Auto cleanup  │
│ • Auto Rotation │    │ • Scanning      │    │ • Retention     │
│ • IAM Policies  │    │ • Policies      │    │ • Cost Control  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🛠️ Development

### Running Examples

```bash
# Basic example
cd examples/basic
terraform init
terraform plan
terraform apply

# Advanced example
cd examples/advanced
terraform init
terraform plan
terraform apply
```

### Testing

```bash
# Validate Terraform files
terraform fmt -check=true -recursive
terraform validate

# Security scanning
tfsec .

# Compliance checking
checkov -d .
```

## 📝 License

This module is released under the MIT License. See [LICENSE](LICENSE) for details.

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📞 Support

For questions, issues, or contributions, please open an issue in this repository.

---

**Made with ❤️ for the DevOps community**

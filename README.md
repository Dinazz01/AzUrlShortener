# AWS ECR Terraform Module

A comprehensive, production-ready Terraform module for creating and managing Amazon Elastic Container Registry (ECR) repositories with advanced features including lifecycle policies, image scanning, replication, and security configurations.

## 🚀 Features

- ✅ **Complete ECR Management**: Repository creation with full configuration options
- ✅ **Security First**: Image scanning, KMS encryption, and access controls
- ✅ **Lifecycle Management**: Automatic image cleanup with custom or default policies
- ✅ **Cross-Region Replication**: Multi-region deployment support
- ✅ **Pull-Through Cache**: Cache public registries for improved performance
- ✅ **Cross-Account Access**: IAM roles for multi-account scenarios
- ✅ **Enhanced Scanning**: Integration with Amazon Inspector
- ✅ **Production Ready**: Comprehensive validation and error handling

## 📁 Project Structure

```
├── modules/
│   └── ecr/                    # Main ECR module
│       ├── main.tf            # Main resources
│       ├── variables.tf       # Input variables
│       ├── outputs.tf         # Output values
│       ├── versions.tf        # Provider requirements
│       └── README.md          # Module documentation
├── examples/
│   ├── basic/                 # Basic usage example
│   ├── enhanced-security/     # Security-focused example
│   └── multi-repository/      # Multiple repositories example
├── main.tf                    # Root configuration example
├── variables.tf               # Root variables
├── terraform.tfvars.example   # Example variables file
└── README.md                  # This file
```

## 🏁 Quick Start

### 1. Basic Usage

```hcl
module "ecr_repository" {
  source = "./modules/ecr"

  repository_name = "my-application"
  
  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

### 2. Advanced Configuration

```hcl
module "ecr_secure" {
  source = "./modules/ecr"

  repository_name      = "secure-api"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  encryption_type     = "KMS"
  kms_key_id          = aws_kms_key.ecr.arn

  # Custom lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### 3. Multiple Repositories

```hcl
locals {
  repositories = {
    frontend = {
      repository_name = "frontend-app"
      environment     = "staging"
    }
    backend = {
      repository_name = "backend-api"
      environment     = "production"
    }
  }
}

module "ecr_repositories" {
  source = "./modules/ecr"
  
  for_each = local.repositories

  repository_name      = each.value.repository_name
  image_tag_mutability = each.value.environment == "production" ? "IMMUTABLE" : "MUTABLE"
  scan_on_push        = true

  tags = {
    Environment = each.value.environment
    Service     = each.key
  }
}
```

## 📚 Examples

Explore the complete examples in the `examples/` directory:

- **[Basic](./examples/basic/)**: Simple ECR repository with default settings
- **[Enhanced Security](./examples/enhanced-security/)**: Production-ready with KMS encryption and strict policies
- **[Multi-Repository](./examples/multi-repository/)**: Multiple repositories with different configurations

## 🛠️ Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- AWS provider >= 5.0

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd aws-ecr-terraform-module
   ```

2. **Copy example variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit variables**:
   ```bash
   # Edit terraform.tfvars with your configuration
   vim terraform.tfvars
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan deployment**:
   ```bash
   terraform plan
   ```

6. **Apply configuration**:
   ```bash
   terraform apply
   ```

### Basic Workflow

```bash
# Initialize
terraform init

# Plan changes
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply -var-file="terraform.tfvars"

# Get ECR login command
terraform output ecr_login_command
```

## 🔧 Configuration

### Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `repository_name` | Name of the ECR repository | `string` | n/a | yes |
| `image_tag_mutability` | Tag mutability (MUTABLE/IMMUTABLE) | `string` | `"MUTABLE"` | no |
| `scan_on_push` | Enable image scanning on push | `bool` | `true` | no |
| `encryption_type` | Encryption type (AES256/KMS) | `string` | `"AES256"` | no |
| `kms_key_id` | KMS key ARN for encryption | `string` | `null` | no |
| `lifecycle_policy` | Custom lifecycle policy JSON | `string` | `null` | no |
| `max_image_count` | Max images to keep (default policy) | `number` | `10` | no |
| `max_image_age_days` | Max image age in days (default policy) | `number` | `30` | no |

### Module Outputs

| Name | Description |
|------|-------------|
| `repository_arn` | Full ARN of the repository |
| `repository_url` | Repository URL for Docker |
| `repository_name` | Name of the repository |
| `registry_id` | Registry ID |

## 🔒 Security Best Practices

### 1. Image Tag Mutability
```hcl
# Production: Use immutable tags
image_tag_mutability = "IMMUTABLE"

# Development: Allow tag overwriting
image_tag_mutability = "MUTABLE"
```

### 2. Encryption
```hcl
# Basic encryption (default)
encryption_type = "AES256"

# Enhanced encryption with KMS
encryption_type = "KMS"
kms_key_id     = aws_kms_key.ecr.arn
```

### 3. Image Scanning
```hcl
# Enable scanning on push
scan_on_push = true

# Enhanced registry scanning
enable_registry_scanning = true
registry_scan_type      = "ENHANCED"
```

### 4. Access Control
```hcl
# Repository policy example
repository_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Sid    = "AllowPushPull"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::ACCOUNT:role/ECRRole"
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage"
      ]
    }
  ]
})
```

## 🎯 Use Cases

### Development Environment
```hcl
module "dev_ecr" {
  source = "./modules/ecr"

  repository_name         = "my-app-dev"
  image_tag_mutability   = "MUTABLE"
  scan_on_push          = false
  max_image_count       = 5
  max_image_age_days    = 7

  tags = {
    Environment = "development"
  }
}
```

### Production Environment
```hcl
module "prod_ecr" {
  source = "./modules/ecr"

  repository_name      = "my-app-prod"
  image_tag_mutability = "IMMUTABLE"
  scan_on_push        = true
  encryption_type     = "KMS"
  kms_key_id          = aws_kms_key.ecr.arn

  # Strict lifecycle policy
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Criticality = "high"
  }
}
```

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Push to ECR

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2

      - name: Login to Amazon ECR
        run: |
          aws ecr get-login-password --region us-west-2 | \
          docker login --username AWS --password-stdin \
          123456789012.dkr.ecr.us-west-2.amazonaws.com

      - name: Build and push image
        run: |
          docker build -t my-app .
          docker tag my-app:latest \
          123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
          docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest
```

## 🧪 Testing

### Validate Module
```bash
# Initialize and validate
terraform init
terraform validate

# Check formatting
terraform fmt -check

# Plan with example variables
terraform plan -var-file="examples/basic/terraform.tfvars"
```

### Test Repository Access
```bash
# Get login token
aws ecr get-login-password --region us-west-2 | \
docker login --username AWS --password-stdin \
123456789012.dkr.ecr.us-west-2.amazonaws.com

# Test push/pull
docker pull hello-world
docker tag hello-world:latest \
123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:test
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:test
```

## 💡 Tips and Best Practices

### 1. Naming Conventions
- Use consistent, descriptive repository names
- Include environment in name for clarity: `app-name-prod`
- Use lowercase and hyphens: `my-web-app`

### 2. Lifecycle Policies
- Implement policies to control costs
- Keep more production images than development
- Clean up untagged images quickly

### 3. Security
- Enable image scanning for all repositories
- Use KMS encryption for sensitive applications
- Implement least-privilege access policies
- Regular security reviews

### 4. Cost Optimization
- Monitor repository sizes regularly
- Use appropriate lifecycle policies
- Consider image layer sharing
- Clean up unused repositories

### 5. Operational Excellence
- Tag all resources consistently
- Use descriptive repository names
- Document custom lifecycle policies
- Monitor scanning results

## 🆘 Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify ECR permissions
   aws ecr describe-repositories
   ```

2. **Docker Login Failed**
   ```bash
   # Get fresh login token
   aws ecr get-login-password --region us-west-2 | \
   docker login --username AWS --password-stdin \
   $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com
   ```

3. **Image Push Failed**
   ```bash
   # Check repository exists
   aws ecr describe-repositories --repository-names my-app
   
   # Verify image tag format
   docker images
   ```

### Getting Help
- Check AWS ECR documentation
- Review Terraform AWS provider docs
- Examine CloudTrail logs for API calls
- Use AWS CLI for direct testing

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For questions, issues, or contributions:
- Open an issue on GitHub
- Check the documentation in `modules/ecr/README.md`
- Review the examples in the `examples/` directory

---

**Happy Container Registering! 🐳**

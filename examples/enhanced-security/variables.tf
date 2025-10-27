variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "secure-production-app"
}

variable "allowed_principals" {
  description = "List of AWS principals allowed to pull images"
  type        = list(string)
  default = [
    # Replace with your actual account ARNs
    # "arn:aws:iam::123456789012:role/production-role"
  ]
}

variable "ci_role_arn" {
  description = "ARN of the CI/CD role allowed to push images"
  type        = string
  default     = ""
  # Example: "arn:aws:iam::123456789012:role/ci-cd-role"
}
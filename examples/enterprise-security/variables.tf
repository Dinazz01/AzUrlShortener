variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "dr_region" {
  description = "Disaster recovery region for replication"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "enterprise-secure-app"
}

variable "production_role_arns" {
  description = "List of production role ARNs allowed to pull images"
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/production-ecs-task-role",
    # "arn:aws:iam::123456789012:role/production-eks-node-role"
  ]
}

variable "ci_role_arns" {
  description = "List of CI/CD role ARNs allowed to push/pull images"
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/github-actions-role",
    # "arn:aws:iam::123456789012:role/jenkins-build-role"
  ]
}

variable "security_notification_emails" {
  description = "List of email addresses for security notifications"
  type        = list(string)
  default = [
    # "security@company.com",
    # "devops@company.com"
  ]
}

variable "cost_notification_emails" {
  description = "List of email addresses for cost notifications"
  type        = list(string)
  default = [
    # "finance@company.com",
    # "cloud-ops@company.com"
  ]
}
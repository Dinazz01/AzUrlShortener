variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "team_name" {
  description = "Name of the team managing these repositories"
  type        = string
  default     = "platform-team"
}
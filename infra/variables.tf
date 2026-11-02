variable "aws_region" {
  description = "AWS region used for the project."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS profile used for the project."
  type        = string
}

variable "project_name" {
  description = "Project name used when naming AWS resources."
  type        = string
  default     = "financial-assistant-poc"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

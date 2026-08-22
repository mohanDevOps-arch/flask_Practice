variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for all resource names/tags"
  type        = string
  default     = "flask-practice"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Host port the Flask container listens on"
  type        = number
  default     = 5000
}

variable "app_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the app port. Tighten for prod."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "notify_emails" {
  description = "Email addresses subscribed to the CI/CD SNS topic. Each recipient must confirm the AWS subscription email once."
  type        = list(string)
  default     = []
}

variable "mongo_uri" {
  description = "MongoDB Atlas connection string. Written to SSM Parameter Store as SecureString."
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Flask session signing key. Written to SSM Parameter Store as SecureString."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Extra tags applied to every taggable resource"
  type        = map(string)
  default     = {}
}

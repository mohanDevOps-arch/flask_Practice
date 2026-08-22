output "aws_region" {
  value = var.aws_region
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "Full ECR repo URL, e.g. 1234.dkr.ecr.us-east-1.amazonaws.com/flask-practice"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Value for the ECR_REPOSITORY GitHub secret"
  value       = aws_ecr_repository.app.name
}

output "ec2_instance_id" {
  description = "Value for the EC2_INSTANCE_ID GitHub secret"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Value for the EC2_HOST GitHub secret"
  value       = aws_eip.app.public_ip
}

output "gha_access_key_id" {
  description = "Value for the AWS_ACCESS_KEY_ID GitHub secret"
  value       = aws_iam_access_key.gha.id
}

output "gha_secret_access_key" {
  description = "Value for the AWS_SECRET_ACCESS_KEY GitHub secret (sensitive)"
  value       = aws_iam_access_key.gha.secret
  sensitive   = true
}

output "gha_user_arn" {
  value = aws_iam_user.gha.arn
}

output "sns_topic_arn" {
  description = "Value for the SNS_TOPIC_ARN GitHub secret"
  value       = aws_sns_topic.ci.arn
}

output "notify_emails" {
  description = "Confirm subscription for each of these inboxes before the pipeline can email you"
  value       = var.notify_emails
}

output "app_url" {
  description = "Convenience URL for the app root"
  value       = "http://${aws_eip.app.public_ip}:${var.app_port}"
}

output "health_url" {
  description = "Convenience URL for the health endpoint"
  value       = "http://${aws_eip.app.public_ip}:${var.app_port}/health"
}

# SSM Parameter Store — runtime secrets for the flask container.
# Values live in terraform.tfvars (gitignored). Rotate with `terraform apply`.

resource "aws_ssm_parameter" "mongo_uri" {
  name        = "/${var.project_name}/mongo_uri"
  description = "MongoDB Atlas connection string for the flask app"
  type        = "SecureString"
  value       = var.mongo_uri
}

resource "aws_ssm_parameter" "secret_key" {
  name        = "/${var.project_name}/secret_key"
  description = "Flask session signing key"
  type        = "SecureString"
  value       = var.secret_key
}

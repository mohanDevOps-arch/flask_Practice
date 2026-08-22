# Remote state in S3. Backend blocks can't reference variables/locals, so
# these values are duplicated in main.tf (locals.tf_state_bucket /
# locals.tf_state_key) for the GHA IAM policy that scopes S3 read access.
# Keep both in sync.
terraform {
  backend "s3" {
    bucket  = "gitops-pipeline-tfstate-512438352764"
    key     = "flask-practice/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

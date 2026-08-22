# Terraform: AWS infra for the CI/CD assignment

Provisions everything the pipeline needs:

- **S3 remote state** — backend config is hardcoded in `backend.tf`
  (`gitops-pipeline-tfstate-512438352764` / `flask-practice/terraform.tfstate`
  / `us-east-1`). The CI pipeline reads outputs from here to discover the
  instance ID, ECR repo, EC2 host, and SNS topic ARN, which is why the
  workflow only needs three AWS secrets.
- **ECR** repository (with lifecycle policy)
- **EC2** instance (Amazon Linux 2023, Docker via user-data, IMDSv2 only)
- **Elastic IP** so `EC2_HOST` doesn't drift on reboot
- **Security group** — port 5000 open by default (no port 22 needed with SSM)
- **IAM instance role**: `AmazonSSMManagedInstanceCore` +
  `AmazonEC2ContainerRegistryReadOnly`, plus scoped `ssm:GetParameter` on the
  two runtime SecureString params
- **SSM Parameter Store** SecureStrings for `MONGO_URI` and `SECRET_KEY` —
  the Ansible playbook fetches these on the instance at deploy time, so they
  never transit the CI runner or CloudTrail command parameters
- **SNS topic** for CI/CD notifications, with email subscriptions
- **IAM user for GitHub Actions**, scoped to:
    - push to the ECR repo
    - `ssm:SendCommand` (via `AWS-RunShellScript` and `AWS-ApplyAnsiblePlaybooks`)
      targeting instances tagged `Project=<project_name>`
    - `sns:Publish` to the CI topic
    - `s3:GetObject` on just the state key in the state bucket

Tradeoff: the GHA user's secret access key lives in Terraform state (in S3,
encrypted) and in GitHub Secrets. To rotate:

```bash
terraform apply -replace=aws_iam_access_key.gha
# then push the new outputs into GitHub secrets — see below
```

## Prerequisites

- Terraform ≥ 1.6
- AWS CLI v2, authenticated as a principal that can create the resources above
- `gh` (GitHub CLI) authenticated on the fork, only if you plan to push secrets
  from the terminal
- The state bucket `gitops-pipeline-tfstate-512438352764` already exists with
  versioning + AES256 encryption + public-access-block enabled. If you're
  starting fresh in a different account, create it once:

  ```bash
  BUCKET=your-tf-state-bucket-name
  REGION=us-east-1

  aws s3api create-bucket \
    --bucket "$BUCKET" \
    --region "$REGION" \
    $( [ "$REGION" = "us-east-1" ] || echo --create-bucket-configuration LocationConstraint=$REGION )
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  ```

  Then update `backend.tf` and the matching `local.tf_state_bucket` in
  `main.tf` to point at your bucket.

## Apply

```bash
cd infra/terraform

cp terraform.tfvars.example terraform.tfvars
# fill in: mongo_uri, secret_key, notify_emails

terraform init      # no -backend-config flags needed
terraform plan
terraform apply
```

## Wire outputs into GitHub secrets

Only three secrets — the workflow reads everything else from `terraform
output` at pipeline run time.

```bash
REPO=immrdg/flask_Practice   # your fork

gh secret set AWS_REGION            --repo "$REPO" --body "$(terraform output -raw aws_region)"
gh secret set AWS_ACCESS_KEY_ID     --repo "$REPO" --body "$(terraform output -raw gha_access_key_id)"
gh secret set AWS_SECRET_ACCESS_KEY --repo "$REPO" --body "$(terraform output -raw gha_secret_access_key)"
```

Runtime app secrets (`MONGO_URI`, `SECRET_KEY`) live in SSM Parameter Store,
not in GitHub — nothing else to set for them.

## Confirm SNS subscriptions

Every address in `notify_emails` receives a "Confirm subscription" email from
AWS after apply. Click the link once per address — unconfirmed subscriptions
receive nothing. Check status with:

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn "$(terraform output -raw sns_topic_arn)" \
  --query 'Subscriptions[].{Endpoint:Endpoint,Status:SubscriptionArn}' \
  --output table
```

`SubscriptionArn: PendingConfirmation` = not yet clicked.

## Verify

```bash
# EC2 came up and SSM registered it
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$(terraform output -raw ec2_instance_id)" \
  --query 'InstanceInformationList[0].{Id:InstanceId,Ping:PingStatus,Platform:PlatformName}'
```

## Destroy

```bash
terraform destroy
```

The ECR repo refuses to delete while it still holds images. Set
`force_delete = true` on `aws_ecr_repository.app` in `main.tf` if you want
`destroy` to wipe images too. The S3 state bucket is intentionally not
managed by terraform — delete it by hand if you want to remove everything.

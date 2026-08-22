# ============================================================================
# EC2 instance role: SSM Session Manager + ECR pull
# ============================================================================
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.project_name}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 needs to read the runtime secrets from Parameter Store at deploy time.
data "aws_iam_policy_document" "ec2_ssm_params" {
  statement {
    sid    = "ReadRuntimeSecrets"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      aws_ssm_parameter.mongo_uri.arn,
      aws_ssm_parameter.secret_key.arn,
    ]
  }

  statement {
    sid       = "DecryptSecureStrings"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ec2_ssm_params" {
  name   = "${var.project_name}-ec2-ssm-params"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.ec2_ssm_params.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2"
  role = aws_iam_role.ec2.name
}

# ============================================================================
# GitHub Actions IAM user (static access keys)
# ============================================================================
# Trade-off vs. OIDC: simpler setup, but the secret lives in Terraform state
# and in GitHub Secrets, and doesn't auto-rotate. Rotate by running
#   terraform apply -replace=aws_iam_access_key.gha
# and re-syncing secrets with scripts/gh-secrets-from-tf.sh.
resource "aws_iam_user" "gha" {
  name = "${var.project_name}-gha"
  path = "/ci/"
}

resource "aws_iam_access_key" "gha" {
  user = aws_iam_user.gha.name
}

data "aws_iam_policy_document" "gha" {
  # ECR: authenticate and push
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = [aws_ecr_repository.app.arn]
  }

  # SSM: send commands to instances tagged with this project.
  statement {
    sid       = "SsmSendCommandToTaggedInstances"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Project"
      values   = [var.project_name]
    }
  }

  # SSM Parameter Store: pipeline stashes each run's ephemeral GITHUB_TOKEN
  # as a SecureString so SSM's AWS-ApplyAnsiblePlaybooks can substitute it
  # into SourceInfo.tokenInfo via {{ssm-secure:...}} — required because that
  # field rejects raw values. Scoped to just the one param path.
  statement {
    sid    = "SsmManageGhTokenParam"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/gha_gh_token",
    ]
  }

  # KMS decrypt for the SSM-managed default key used to encrypt the token
  # SecureString (both when SSM resolves {{ssm-secure:...}} and when the
  # pipeline overwrites the param).
  statement {
    sid       = "SsmGhTokenKms"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.aws_region}.amazonaws.com"]
    }
  }

  # SSM: using the AWS-managed documents we actually invoke.
  statement {
    sid     = "SsmSendCommandUsingApprovedDocuments"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]
    resources = [
      "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript",
      "arn:aws:ssm:${var.aws_region}::document/AWS-ApplyAnsiblePlaybooks",
    ]
  }

  # SSM: read the command result. These actions don't support resource-level
  # restrictions; scope stays account-wide.
  statement {
    sid    = "SsmReadCommand"
    effect = "Allow"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands",
    ]
    resources = ["*"]
  }

  # SNS: publish CI/CD notifications to the single topic we own.
  statement {
    sid       = "SnsPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.ci.arn]
  }

  # S3: read the remote terraform state so the pipeline can `terraform output`
  # to discover instance id / EC2 host / ECR repo / SNS topic. Read-only —
  # the pipeline never runs `terraform apply`.
  statement {
    sid       = "TfStateBucketList"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketVersioning"]
    resources = ["arn:aws:s3:::${local.tf_state_bucket}"]
  }

  statement {
    sid    = "TfStateObjectRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
    ]
    resources = [
      "arn:aws:s3:::${local.tf_state_bucket}/${local.tf_state_key}",
    ]
  }

  # KMS: SNS topic uses the AWS-managed 'alias/aws/sns' key. Publisher needs
  # GenerateDataKey / Decrypt to publish through it.
  statement {
    sid    = "SnsKms"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${var.aws_region}.amazonaws.com"]
    }
  }
}

# Managed policy (not inline) because the combined statements exceed the
# 2048-byte inline user-policy limit once the SSM-secure token plumbing
# and S3 remote-state read are added.
resource "aws_iam_policy" "gha" {
  name        = "${var.project_name}-gha"
  description = "CI/CD permissions for the ${var.project_name} GitHub Actions user"
  policy      = data.aws_iam_policy_document.gha.json
}

resource "aws_iam_user_policy_attachment" "gha" {
  user       = aws_iam_user.gha.name
  policy_arn = aws_iam_policy.gha.arn
}

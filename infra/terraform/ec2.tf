# Amazon Linux 2023 (latest) — resolved from the AWS-managed SSM parameter.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023_ami.value
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # IMDSv2 only
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
  }

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # First-boot bootstrap. Installs Docker + confirms SSM agent so the pipeline
  # can deploy immediately after `terraform apply`. Idempotent; safe on reboot.
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf update -y
    dnf install -y docker

    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent

    # Let ec2-user run docker without sudo
    usermod -aG docker ec2-user || true
  EOF

  tags = {
    Name = "${var.project_name}-app"
  }

  # Ensure the ECR-read policy is attached before the instance comes up, so
  # the first pipeline run doesn't race the policy attachment.
  depends_on = [
    aws_iam_role_policy_attachment.ec2_ecr,
    aws_iam_role_policy_attachment.ec2_ssm,
  ]
}

resource "aws_eip" "app" {
  instance = aws_instance.app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-app"
  }
}

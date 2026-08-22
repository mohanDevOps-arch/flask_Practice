# SNS topic + email subscriptions for CI/CD notifications.
#
# Each recipient in var.notify_emails gets an AWS confirmation email once
# `terraform apply` completes. The subscription stays PendingConfirmation
# until the recipient clicks the link — subsequent publishes are silently
# dropped for unconfirmed subscribers.
resource "aws_sns_topic" "ci" {
  name              = "${var.project_name}-ci"
  display_name      = "CI/CD" # shown as the sender name in email
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "ci_email" {
  for_each = toset(var.notify_emails)

  topic_arn = aws_sns_topic.ci.arn
  protocol  = "email"
  endpoint  = each.value
}

# Least-privilege publish permission is expressed on the GHA policy in iam.tf;
# see the SnsPublish statement there.

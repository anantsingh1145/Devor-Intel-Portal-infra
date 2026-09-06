# No terraform-aws-modules registry module exists for Bedrock IAM wiring, so
# this uses native resources directly, per the "use resources where no module
# fits" rule for this repo.
#
# Grants the ECS task role permission to invoke Claude via a Bedrock
# cross-region inference profile, replacing a direct Anthropic API key.
# Per Bedrock's IAM requirements, BOTH the inference profile ARN and the
# underlying foundation model ARN (wildcard region) must be granted together,
# since a request may be routed to any region within the profile.

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "bedrock_invoke" {
  statement {
    sid = "InvokeClaudeOnBedrock"

    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]

    resources = [
      "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.inference_profile_id}",
      "arn:aws:bedrock:*::foundation-model/${var.foundation_model_id}",
    ]
  }

  # Anthropic models are sold through AWS Marketplace - Bedrock auto-subscribes
  # on the first-ever invocation of a given model in the account, but only if
  # the calling identity holds these. Without them, that first call fails with
  # AccessDeniedException instead of self-healing. Not scoped by product ID:
  # ViewSubscriptions/Unsubscribe don't support resource-level scoping at all,
  # and this only covers the one-time auto-enable, not ongoing invoke access.
  statement {
    sid = "MarketplaceAutoSubscribe"

    actions = [
      "aws-marketplace:Subscribe",
      "aws-marketplace:Unsubscribe",
      "aws-marketplace:ViewSubscriptions",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "bedrock_invoke" {
  name   = "${var.name_prefix}-bedrock-invoke"
  policy = data.aws_iam_policy_document.bedrock_invoke.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "task_bedrock" {
  role       = var.task_role_name
  policy_arn = aws_iam_policy.bedrock_invoke.arn
}

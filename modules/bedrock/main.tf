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

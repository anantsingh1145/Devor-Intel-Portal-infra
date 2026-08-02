output "policy_arn" {
  description = "ARN of the Bedrock invoke policy attached to the ECS task role."
  value       = aws_iam_policy.bedrock_invoke.arn

  # The policy ARN exists as soon as the policy is created, but the task role
  # actually needs the ATTACHMENT to exist before a task using that role can
  # invoke Bedrock. depends_on the attachment so consumers of this output
  # (and anything ordered after module.bedrock) wait for that too.
  depends_on = [aws_iam_role_policy_attachment.task_bedrock]
}

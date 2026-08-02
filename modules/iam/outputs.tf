output "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  value       = aws_iam_role.execution.arn

  # The role ARN exists as soon as aws_iam_role.execution is created, but ECS
  # needs the role to actually BE ABLE to pull from ECR / write logs / read
  # secrets when a task starts. Without this, Terraform can hand this ARN to
  # the fargate module before the policy attachment/inline policy finish.
  depends_on = [
    aws_iam_role_policy_attachment.execution_managed,
    aws_iam_role_policy.execution_secrets,
  ]
}

output "task_role_arn" {
  description = "ARN of the ECS task role."
  value       = aws_iam_role.task.arn

  # Same reasoning: the task needs its EFS mount permission in place before
  # it starts, not just the bare role.
  depends_on = [aws_iam_role_policy.task_efs]
}

output "task_role_name" {
  description = "Name of the ECS task role, consumed by modules/bedrock to attach the Bedrock invoke policy."
  value       = aws_iam_role.task.name
}

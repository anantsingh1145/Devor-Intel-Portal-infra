# No terraform-aws-modules registry module cleanly covers ECS task/execution
# roles (their iam module is EKS/IRSA-focused), so this uses native
# aws_iam_role/aws_iam_role_policy resources directly, per the "use resources
# where no module fits" rule for this repo.

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- Execution role: pulls the image from ECR, writes to CloudWatch Logs,
#     and resolves `secrets` in the container definition at task startup. ---

resource "aws_iam_role" "execution" {
  name               = "${var.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secret_arns
  }
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  name   = "${var.name_prefix}-secrets-read"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.execution_secrets[0].json
}

# --- Task role: what the running container itself is allowed to do — here,
#     mount and read/write the EFS access point holding chronicle.db. ---

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "task_efs" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeMountTargets",
    ]
    resources = [var.efs_file_system_arn]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [var.efs_access_point_arn]
    }
  }
}

resource "aws_iam_role_policy" "task_efs" {
  name   = "${var.name_prefix}-efs-access"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_efs.json
}

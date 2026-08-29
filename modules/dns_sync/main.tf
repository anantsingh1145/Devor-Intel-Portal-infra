# No terraform-aws-modules registry module covers this Lambda+EventBridge
# combination, so this uses native resources directly, per the "use
# resources where no module fits" rule for this repo.
#
# There's no ALB in this architecture, so nothing keeps DNS in sync with the
# ECS task's public IP, which changes on every restart/redeploy/autoscaling
# event. This Lambda listens for the task reaching RUNNING, looks up its
# ENI's public IP, and upserts modules/route53's A record to match.
#
# NOTE: this was designed against documented ECS Task State Change event
# shapes, not verified against a live event in this environment (no working
# AWS credentials at the time this was built). The Lambda logs the full
# incoming event on every invocation — check CloudWatch Logs
# (/aws/lambda/<name_prefix>-dns-sync) after the first task start to confirm
# it actually fired and updated the record as expected.

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/update_dns.py"
  output_path = "${path.module}/lambda/update_dns.zip"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-dns-sync-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid       = "DescribeNetworkInterfaces"
    actions   = ["ec2:DescribeNetworkInterfaces"]
    resources = ["*"] # DescribeNetworkInterfaces does not support resource-level permissions
  }

  statement {
    sid       = "UpdateRoute53Record"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
  }

  statement {
    sid = "LambdaLogging"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name_prefix}-dns-sync-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_lambda_function" "dns_sync" {
  function_name = "${var.name_prefix}-dns-sync"
  role          = aws_iam_role.lambda.arn
  handler       = "update_dns.handler"
  runtime       = "python3.13"
  timeout       = 30

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      HOSTED_ZONE_ID = var.route53_zone_id
      RECORD_NAME    = var.domain_name
      RECORD_TTL     = tostring(var.record_ttl)
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "task_running" {
  name        = "${var.name_prefix}-dns-sync-task-running"
  description = "Fires when a Chronicle ECS task transitions to RUNNING, so its public IP can be synced to Route 53."

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn    = [var.ecs_cluster_arn]
      lastStatus    = ["RUNNING"]
      desiredStatus = ["RUNNING"]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "dns_sync" {
  rule      = aws_cloudwatch_event_rule.task_running.name
  target_id = "dns-sync-lambda"
  arn       = aws_lambda_function.dns_sync.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_sync.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.task_running.arn
}

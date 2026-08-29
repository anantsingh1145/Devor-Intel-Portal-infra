aws_region   = "ap-south-1"
project_name = "devor"
environment  = "prod"

# --- Networking ---
vpc_cidr            = "10.0.0.0/16"
azs                 = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

# --- App / container ---
app_port          = 8501
health_check_path = "/"
image_tag         = "latest"

task_cpu      = 512
task_memory   = 1024
desired_count = 1

container_mount_path = "/data"

app_environment = {
  # chronicle@devor.net is GoDaddy Workspace Email — smtpout.secureserver.net
  # authenticates with that mailbox's regular password (no separate app
  # password for this product, unlike Gmail/Microsoft 365).
  SMTP_HOST        = "smtpout.secureserver.net"
  SMTP_PORT        = "587"
  SMTP_USER        = "chronicle@devor.net"
  EMAIL_RECIPIENTS = "you@example.com"
  # Points the app's SQLite file at the EFS mount (container_mount_path
  # above) so chronicle.db survives task restarts/redeploys.
  CHRONICLE_DB_PATH = "/data/chronicle.db"
}
# BEDROCK_MODEL_ID and AWS_REGION are merged into the container's environment
# in main.tf (from bedrock_inference_profile_id/aws_region below) — not
# listed here, to keep the model ID in one place.

# secret_names uses its default (SERPER_API_KEY, SMTP_PASSWORD, WEBHOOK_URL) —
# no code-supplied values anywhere. Set each one manually after apply:
#   aws secretsmanager put-secret-value --secret-id devor/prod/SERPER_API_KEY --secret-string '<value>'
# (repeat per secret). The ECS task will fail to start until all 3 have values.

# --- Bedrock (Claude via AWS Bedrock, no Anthropic API key needed) ---
# PLACEHOLDERS — verify before applying:
#   aws bedrock list-inference-profiles --region ap-south-1
#   aws bedrock list-foundation-models --region ap-south-1
# ap-south-1 may not host Claude directly; a cross-region profile (e.g. an
# "apac." prefix) may be required, and its primary invocation region may
# differ from ap-south-1 — confirm both before relying on this.
bedrock_inference_profile_id = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
bedrock_foundation_model_id  = "anthropic.claude-haiku-4-5-20251001-v1:0"

# --- Autoscaling ---
enable_autoscaling       = true
autoscaling_min_capacity = 1
autoscaling_max_capacity = 2
autoscaling_cpu_target   = 65

# Keep one task on regular Fargate (fargate_base = 1 in modules/fargate) and
# mix in Spot for the rest — a cost/reliability middle ground since this is
# currently the only environment.
fargate_spot_weight = 50

# --- Observability ---
container_insights_enabled = false
log_retention_in_days      = 30

# --- ECR ---
ecr_image_retention_count = 10
ecr_force_delete          = false

# --- EFS ---
efs_posix_uid = 1000
efs_posix_gid = 1000

# --- No custom domain yet: reach it via the ALB's own DNS name over HTTP ---
domain_name     = ""
route53_zone_id = ""

# --- Budget alert: replace with your real email before applying ---
monthly_budget_usd         = "20"
budget_notification_emails = ["chronicle@devor.net"]

tags = {
  Owner = "anantsingh1145"
}

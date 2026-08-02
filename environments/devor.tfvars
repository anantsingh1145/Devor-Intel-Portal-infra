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
  SMTP_HOST        = "smtp.gmail.com"
  SMTP_PORT        = "587"
  SMTP_USER        = "chronicle@example.com"
  EMAIL_RECIPIENTS = "you@example.com"
}
# Real secret values (ANTHROPIC_API_KEY, SMTP_PASSWORD, ...) go in a
# gitignored devor.secrets.tfvars — see devor.secrets.tfvars.example.
# In CI, the same map is supplied via the TF_VAR_secrets env var instead
# (see .github/workflows/deploy-infra.yaml).

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

tags = {
  Owner = "anantsingh1145"
}

# Every variable here is meant to be supplied by an environments/<env>.tfvars
# file (see environments/devor.tfvars for the full set). This file itself
# never changes between environments — only the values passed in do.

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "project_name" {
  description = "Short project name used as a prefix for resource names (e.g. \"chronicle\")."
  type        = string
  default     = "chronicle"
}

variable "environment" {
  description = "Environment name, e.g. \"dev\", \"preprod\", \"prod\"."
  type        = string
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability zones to spread public subnets across (at least 2, required by the ALB)."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ in var.azs."
  type        = list(string)
}

# --- App / container ---

variable "app_port" {
  description = "Port the Chronicle (Streamlit) container listens on."
  type        = number
  default     = 8501
}

variable "health_check_path" {
  description = "HTTP path the ECS container-level health check requests (no ALB in this architecture, so this is what lets ECS detect and replace an unhealthy task)."
  type        = string
  default     = "/"
}

variable "image_tag" {
  description = "Tag of the image in ECR to deploy, e.g. \"latest\" or a git SHA."
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "Task-level vCPU units (Fargate: 256/512/1024/2048/...)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Task-level memory in MiB, must be a valid Fargate cpu/memory pairing."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to run."
  type        = number
  default     = 1
}

variable "container_mount_path" {
  description = "Path inside the container where the EFS volume (holding chronicle.db) is mounted."
  type        = string
  default     = "/data"
}

variable "app_environment" {
  description = "Plain (non-secret) environment variables passed to the container, e.g. SMTP_HOST/SMTP_PORT."
  type        = map(string)
  default     = {}
}

variable "secret_names" {
  description = "Container env var names to create as empty Secrets Manager secrets (e.g. [\"SERPER_API_KEY\", \"SMTP_PASSWORD\"]). Terraform only creates the secret container — no value is ever set here or anywhere else in code. Populate the actual value manually after apply, e.g. `aws secretsmanager put-secret-value --secret-id <name> --secret-string '<value>'`, or via the console. The task will fail to start until every secret listed here has a value."
  type        = list(string)
  default     = ["SERPER_API_KEY", "SMTP_PASSWORD", "WEBHOOK_URL"]
}

# --- Bedrock (Claude via AWS Bedrock, replacing a direct Anthropic API key) ---

variable "bedrock_inference_profile_id" {
  description = "Cross-region inference profile ID for Claude on Bedrock, e.g. \"apac.anthropic.claude-<model>-<date>-v<N>:0\". PLACEHOLDER — verify the current one for your account/region with `aws bedrock list-inference-profiles --region <region>` before applying; Bedrock model IDs change over time and are not guessed here."
  type        = string
}

variable "bedrock_foundation_model_id" {
  description = "Base foundation model ID underlying var.bedrock_inference_profile_id, without the geographic prefix, e.g. \"anthropic.claude-<model>-<date>-v<N>:0\". Needed alongside the inference profile ARN because Bedrock may route the request to any region within the profile — verify with `aws bedrock list-foundation-models --region <region>`."
  type        = string
}

# --- Autoscaling ---

variable "enable_autoscaling" {
  description = "Enable target-tracking autoscaling on CPU utilization."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks."
  type        = number
  default     = 2
}

variable "autoscaling_cpu_target" {
  description = "Target average CPU utilization percentage for autoscaling."
  type        = number
  default     = 60
}

variable "fargate_spot_weight" {
  description = "Relative weight for FARGATE_SPOT capacity in the cluster/service placement strategy. Set > 0 in cost-sensitive, non-prod environments; keep 0 in prod for reliability."
  type        = number
  default     = 0
}

# --- Observability ---

variable "container_insights_enabled" {
  description = "Enable CloudWatch Container Insights on the ECS cluster (small extra cost)."
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "How long CloudWatch retains the container's logs."
  type        = number
  default     = 30
}

# --- ECR ---

variable "ecr_image_retention_count" {
  description = "Maximum number of tagged images to retain in ECR before older ones expire."
  type        = number
  default     = 10
}

variable "ecr_force_delete" {
  description = "Allow deleting the ECR repository even if it still contains images (handy for dev/preprod, keep false in prod)."
  type        = bool
  default     = false
}

# --- EFS ---

variable "efs_posix_uid" {
  description = "POSIX UID enforced by the EFS access point (must match the container's runtime user)."
  type        = number
  default     = 1000
}

variable "efs_posix_gid" {
  description = "POSIX GID enforced by the EFS access point (must match the container's runtime group)."
  type        = number
  default     = 1000
}

# --- Optional custom domain (leave both empty to skip ACM/HTTPS/Route53) ---

variable "domain_name" {
  description = "Custom domain to serve Chronicle on, e.g. \"chronicle.example.com\". Leave empty to serve plain HTTP on the ALB's own DNS name."
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for var.domain_name. Required when domain_name is set."
  type        = string
  default     = ""
}

# --- Budget alert ---

variable "monthly_budget_usd" {
  description = "Monthly AWS spend limit (USD) that triggers budget alert emails."
  type        = string
  default     = "20"
}

variable "budget_notification_emails" {
  description = "Email addresses to notify when spend crosses an alert threshold. Required — AWS Budgets needs at least one subscriber."
  type        = list(string)
}

variable "tags" {
  description = "Extra tags merged into every resource's tags, in addition to the automatic Project/Environment/ManagedBy tags."
  type        = map(string)
  default     = {}
}

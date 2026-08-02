# Devor-Intel-Portal-infra

Terraform for hosting [Chronicle](https://github.com/anantsingh1145/Chronicle-The-DevOps-Intel-Portal) (a Streamlit app backed by SQLite) on AWS: ECS Fargate + ALB + EFS, built from official `terraform-aws-modules` registry modules wherever one exists, with plain `aws_*` resources only where it doesn't (IAM roles, Secrets Manager, CloudWatch Log Group). Deployed to **ap-south-1**.

## Architecture

```
Internet -> ALB (HTTP/HTTPS) -> ECS Fargate service (public subnets, no NAT) -> EFS (chronicle.db)
                                        |
                                        +-- Secrets Manager (ANTHROPIC_API_KEY, SMTP_PASSWORD, ...)
                                        +-- CloudWatch Logs
```

- **No NAT Gateway** — tasks run in public subnets with public IPs, reachable only via the ALB's security group. Saves ~$32/month over a private-subnet + NAT setup.
- **EFS** persists `chronicle.db` across task restarts/redeploys, since a Fargate task's local disk is ephemeral.
- **HTTPS/Route 53 are optional** — leave `domain_name`/`route53_zone_id` empty (as in `devor.tfvars`) and the app is served over plain HTTP on the ALB's own DNS name.
- **FARGATE_SPOT** is mixed in via `fargate_spot_weight` for cost savings while keeping `fargate_base = 1` task on regular Fargate.

## Layout

```
modules/
  vpc/              terraform-aws-modules/vpc/aws
  security_groups/  terraform-aws-modules/security-group/aws (x3: alb, ecs task, efs)
  ecr/              terraform-aws-modules/ecr/aws
  acm/              terraform-aws-modules/acm/aws (optional, created only if domain_name is set)
  lb/               terraform-aws-modules/alb/aws
  efs/              terraform-aws-modules/efs/aws
  ecs/              terraform-aws-modules/ecs/aws (cluster only)
  fargate/          terraform-aws-modules/ecs/aws//modules/service (task definition + service)
  iam/              native aws_iam_role/aws_iam_role_policy (no clean registry module for ECS task roles)
  secrets/          native aws_secretsmanager_secret (no registry module fits a simple N-secrets case)
  logs/             native aws_cloudwatch_log_group
  route53/          terraform-aws-modules/route53/aws//modules/records (optional)
main.tf             root module: wires every module above using only var.*
variables.tf        every variable that can be set per environment
outputs.tf          ALB URL, ECR repo URL, cluster/service names, etc.
providers.tf        AWS provider + partial S3 backend (real values come from environments/backend.hcl)
environments/
  devor.tfvars                  committed, non-secret values
  devor.secrets.tfvars.example  committed template; copy to devor.secrets.tfvars (gitignored) with real values
  backend.hcl                   S3 backend config (bucket/key/region)
.github/workflows/
  deploy-infra.yaml             CI: tfsec -> plan -> (manual approval) -> apply
```

Only one environment (`devor`) is set up right now. The module/root code is still environment-agnostic — adding a second environment later (e.g. `staging`) is just: copy `devor.tfvars` to `staging.tfvars`, copy `devor.secrets.tfvars.example` to `staging.secrets.tfvars`, add a `backend-staging.hcl` with its own `key`, and pass those files instead. No `.tf` code changes needed.

## Prerequisites

- Terraform >= 1.6 (native S3 state locking via `use_lockfile` needs >= 1.10 — this repo assumes a recent Terraform; check with `terraform version`).
- AWS credentials for the account you're deploying into (`aws configure` or env vars) for local runs; CI uses OIDC (see below).
- A Docker image of Chronicle pushed to the ECR repo this code creates (see "First deploy" below — you push the image *after* `ecr` exists but *before* the `fargate` service can start successfully).

## Bootstrapping remote state (one-time)

State is stored in S3 bucket **`devor-infra-state-file`** (`environments/backend.hcl`). Terraform can't create the bucket it stores its own state in (chicken-and-egg), so create it once manually before the first `terraform init`:

```bash
aws s3api create-bucket --bucket devor-infra-state-file --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1
aws s3api put-bucket-versioning --bucket devor-infra-state-file \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket devor-infra-state-file \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

## Usage (local)

```bash
# 1. Copy the secrets template and fill in real values (never commit this file)
cp environments/devor.secrets.tfvars.example environments/devor.secrets.tfvars

# 2. Init against the backend
terraform init -backend-config=environments/backend.hcl

# 3. Plan / apply with both var files
terraform plan  -var-file=environments/devor.tfvars -var-file=environments/devor.secrets.tfvars
terraform apply -var-file=environments/devor.tfvars -var-file=environments/devor.secrets.tfvars
```

### First deploy

The `fargate` module references `module.ecr.repository_url`, so `terraform apply` will create the ECR repo before the ECS service — but the service won't reach a healthy state until an image actually exists at `<repository_url>:<image_tag>`. First deploy:

```bash
terraform apply -var-file=environments/devor.tfvars -var-file=environments/devor.secrets.tfvars -target=module.ecr
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.ap-south-1.amazonaws.com
docker build -t <repository_url>:latest .
docker push <repository_url>:latest
terraform apply -var-file=environments/devor.tfvars -var-file=environments/devor.secrets.tfvars
```

### Redeploying a new image

Push a new tag and either bump `image_tag` in `devor.tfvars`, or force a fresh deployment of the same tag:

```bash
aws ecs update-service --cluster <ecs_cluster_name output> --service <ecs_service_name output> --force-new-deployment
```

## CI/CD (`.github/workflows/deploy-infra.yaml`)

Triggers on push to `main` (paths: `modules/**`, `environments/**`, `*.tf`) or manual dispatch. Three jobs, strictly sequential (`needs:`), plus a repo-wide `concurrency` group so two runs can never plan/apply against the same state at once:

1. **tfsec** — fails the pipeline on any security finding (`soft_fail: false`).
2. **Terraform Plan** — assumes an AWS IAM role via OIDC (no long-lived AWS keys in GitHub), runs `fmt -check`, `validate`, then `plan -out=tfplan` and uploads `tfplan` as a build artifact.
3. **Terraform Apply** — downloads `tfplan` and runs `terraform apply tfplan` (the saved plan, not a fresh one, so what gets applied is exactly what was reviewed). Gated by the `prod` GitHub Environment.

**One-time GitHub setup required before this pipeline can run:**

- **OIDC role secret** — `AWS_DEVOR_OIDC_SA` repo secret holding the IAM role ARN to assume (already created per your setup).
- **App secrets for Terraform** — add a `DEVOR_TF_SECRETS_JSON` repo secret containing the JSON-encoded form of the `secrets` map var (see `environments/devor.secrets.tfvars.example` for the required keys), e.g.:
  ```json
  {"ANTHROPIC_API_KEY": "sk-ant-...", "SERPER_API_KEY": "...", "SMTP_PASSWORD": "...", "WEBHOOK_URL": "..."}
  ```
  This is injected as `TF_VAR_secrets` during `plan`; the saved plan then carries the resolved values into `apply`, so `apply` needs no secrets of its own.
- **Manual approval gate** — in the repo, go to **Settings > Environments > New environment**, name it `prod`, and add yourself (or your team) as a required reviewer. Until this exists, the `terraform-apply` job will run immediately after plan with no gate.

## Creating the Secrets Manager secrets without a local plaintext file

`environments/devor.secrets.tfvars` is gitignored, but if you'd rather not have real secret values sitting in a file on disk at all, supply them as a one-shot shell environment variable instead — it never touches disk and only exists for that command:

```bash
# Leading space keeps this out of shell history on bash/zsh with HIST_IGNORE_SPACE/HISTCONTROL=ignorespace set.
 export TF_VAR_secrets='{"ANTHROPIC_API_KEY":"...","SERPER_API_KEY":"...","SMTP_PASSWORD":"...","WEBHOOK_URL":"..."}'

terraform init -backend-config=environments/backend.hcl
terraform apply -var-file=environments/devor.tfvars -target=module.secrets

unset TF_VAR_secrets
```

`-target=module.secrets` scopes this to just creating the Secrets Manager secrets (and their versions), without touching the rest of the stack — useful for bootstrapping secrets before the full infra exists. Run the full `terraform apply` (no `-target`) once you're ready to provision everything else; `module.iam`'s execution role will then be granted read access to exactly these secrets.

## Cost (approximate, ap-south-1, single-task setup)

| Resource | ~Monthly Cost (USD) |
|---|---|
| ECS Fargate (1 task, 0.5 vCPU/1GB) | $18 |
| ALB | $18–20 |
| EFS | $1 |
| Secrets Manager | $1 |
| CloudWatch Logs | $1 |
| ECR | $0.10 |
| Data transfer | $2–5 |

**Total: ~$40–47/month.** Cost knobs already wired up: `fargate_spot_weight`, `task_cpu`/`task_memory`, `desired_count`, `log_retention_in_days`, `container_insights_enabled`.

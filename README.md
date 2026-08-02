# Devor-Intel-Portal-infra

Terraform for hosting [Chronicle](https://github.com/anantsingh1145/Chronicle-The-DevOps-Intel-Portal) (a Streamlit app backed by SQLite) on AWS: ECS Fargate + ALB + EFS, built from official `terraform-aws-modules` registry modules wherever one exists, with plain `aws_*` resources only where it doesn't (IAM roles, Secrets Manager, CloudWatch Log Group, Bedrock IAM wiring). Deployed to **ap-south-1**.

## Architecture

```
Internet -> ALB (HTTP/HTTPS) -> ECS Fargate service (public subnets, no NAT) -> EFS (chronicle.db)
                                        |
                                        +-- Bedrock (Claude, via task role IAM — no API key)
                                        +-- Secrets Manager (SERPER_API_KEY, SMTP_PASSWORD, WEBHOOK_URL)
                                        +-- CloudWatch Logs
```

- **No NAT Gateway** — tasks run in public subnets with public IPs, reachable only via the ALB's security group. Saves ~$32/month over a private-subnet + NAT setup.
- **EFS** persists `chronicle.db` across task restarts/redeploys, since a Fargate task's local disk is ephemeral.
- **HTTPS/Route 53 are optional** — leave `domain_name`/`route53_zone_id` empty (as in `devor.tfvars`) and the app is served over plain HTTP on the ALB's own DNS name.
- **FARGATE_SPOT** is mixed in via `fargate_spot_weight` for cost savings while keeping `fargate_base = 1` task on regular Fargate.
- **Claude via Bedrock, not a direct Anthropic API key** — the ECS task role is granted `bedrock:InvokeModel`/`InvokeModelWithResponseStream` scoped to a specific inference profile. No `ANTHROPIC_API_KEY` exists anywhere in this repo.

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
  bedrock/          native aws_iam_policy (no registry module for Bedrock IAM wiring) — grants the task role Claude invoke permission
  secrets/          native aws_secretsmanager_secret — creates EMPTY secret containers only, no values ever pass through Terraform
  logs/             native aws_cloudwatch_log_group
  route53/          terraform-aws-modules/route53/aws//modules/records (optional)
main.tf             root module: wires every module above using only var.*
variables.tf        every variable that can be set per environment
outputs.tf          ALB URL, ECR repo URL, cluster/service names, etc.
providers.tf        AWS provider + partial S3 backend (real values come from environments/backend.hcl)
environments/
  devor.tfvars      committed, non-secret values (no secret values exist anywhere in this repo)
  backend.hcl       S3 backend config (bucket/key/region)
.github/workflows/
  deploy-infra.yaml CI: tfsec -> plan -> (manual approval) -> apply
```

Only one environment (`devor`) is set up right now. The module/root code is still environment-agnostic — adding a second environment later (e.g. `staging`) is just: copy `devor.tfvars` to `staging.tfvars`, add a `backend-staging.hcl` with its own `key`, and pass those files instead. No `.tf` code changes needed.

## Prerequisites

- Terraform >= 1.6 (native S3 state locking via `use_lockfile` needs >= 1.10 — this repo assumes a recent Terraform; check with `terraform version`).
- AWS credentials for the account you're deploying into (`aws configure` or env vars) for local runs; CI uses OIDC (see below).
- A Docker image of Chronicle pushed to the ECR repo this code creates (see "First deploy" below — you push the image *after* `ecr` exists but *before* the `fargate` service can start successfully).
- Claude model access enabled on Bedrock in your account/region (see "Bedrock setup" below) — this is a one-time manual step Terraform cannot perform.

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

## Bedrock setup (one-time, required before Claude calls will work)

Terraform grants the *permission* to call Bedrock, but two things happen outside Terraform entirely:

1. **Confirm the current model ID for your region.** Bedrock model IDs are not guessed in this repo — `bedrock_inference_profile_id`/`bedrock_foundation_model_id` in `environments/devor.tfvars` are placeholders. Verify and replace them:
   ```bash
   aws bedrock list-foundation-models --region ap-south-1
   aws bedrock list-inference-profiles --region ap-south-1
   ```
   ap-south-1 may not host Claude directly — if not, use a cross-region inference profile (e.g. an `apac.` prefix) and confirm which region it actually invokes against.
2. **Accept the model's usage terms.** Anthropic models on Bedrock require a one-time usage-form submission per account before first use — via the Bedrock console (Model access page) or the `PutUseCaseForModelAccess` API. There is no stable Terraform resource for this.

Until both are done, `terraform apply` will succeed (the IAM policy doesn't validate the model ID), but the running task will get `AccessDeniedException`/`ValidationException` from Bedrock at runtime.

**Also out of scope for this repo:** the Chronicle app's own code (`backend.py`, CrewAI/LangChain setup) currently calls the Anthropic API directly via `langchain-anthropic` and `ANTHROPIC_API_KEY`. That needs a corresponding app-side change (e.g. to `langchain-aws`'s `ChatBedrock`, reading `BEDROCK_MODEL_ID` from the environment) — this infra only sets up the AWS side.

## Usage (local)

```bash
terraform init -backend-config=environments/backend.hcl
terraform plan  -var-file=environments/devor.tfvars
terraform apply -var-file=environments/devor.tfvars
```

No secrets file is needed for `plan`/`apply` — `secret_names` is just a list of names, and no secret *values* are ever supplied through Terraform. See "Populating the secrets" below for setting the actual values.

### First deploy

The `fargate` module references `module.ecr.repository_url`, so `terraform apply` will create the ECR repo before the ECS service — but the service won't reach a healthy state until an image actually exists at `<repository_url>:<image_tag>` **and** the 3 secrets below have real values. First deploy:

```bash
terraform apply -var-file=environments/devor.tfvars -target=module.ecr
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.ap-south-1.amazonaws.com
docker build -t <repository_url>:latest .
docker push <repository_url>:latest
terraform apply -var-file=environments/devor.tfvars
```

Then populate the secrets (see below) before expecting the task to reach a healthy state.

### Redeploying a new image

Push a new tag and either bump `image_tag` in `devor.tfvars`, or force a fresh deployment of the same tag:

```bash
aws ecs update-service --cluster <ecs_cluster_name output> --service <ecs_service_name output> --force-new-deployment
```

## Populating the secrets

`modules/secrets` creates only the Secrets Manager **containers** (`SERPER_API_KEY`, `SMTP_PASSWORD`, `WEBHOOK_URL`) — no value is ever set by Terraform, by design, so no secret material lives in this repo, in tfvars, or in CI. Set each one manually after `terraform apply`:

```bash
aws secretsmanager put-secret-value --secret-id devor/prod/SERPER_API_KEY --secret-string '<value>'
aws secretsmanager put-secret-value --secret-id devor/prod/SMTP_PASSWORD  --secret-string '<value>'
aws secretsmanager put-secret-value --secret-id devor/prod/WEBHOOK_URL    --secret-string '<value>'
```

(Secret name prefix is `<project_name>/<environment>` — `devor/prod` for the current `devor.tfvars`.) The ECS task will fail to start with a `ResourceInitializationError` until all three have values. Re-running `terraform apply` afterwards will not touch or overwrite whatever value you've set — Terraform only manages the container, never the version.

## CI/CD (`.github/workflows/deploy-infra.yaml`)

Triggers on push to `main` (paths: `modules/**`, `environments/**`, `*.tf`) or manual dispatch. Three jobs, strictly sequential (`needs:`), plus a repo-wide `concurrency` group so two runs can never plan/apply against the same state at once:

1. **tfsec** — fails the pipeline on any security finding (`soft_fail: false`).
2. **Terraform Plan** — assumes an AWS IAM role via OIDC (no long-lived AWS keys in GitHub), runs `fmt -check`, `validate`, then `plan -out=tfplan`, encrypts the plan (GPG, symmetric) and uploads it as a build artifact.
3. **Terraform Apply** — downloads and decrypts the plan, then runs `terraform apply tfplan` (the saved plan, not a fresh one, so what gets applied is exactly what was reviewed). Gated by the `prod` GitHub Environment.

**One-time GitHub/AWS setup required before this pipeline can run:**

- **OIDC role secret** — `AWS_DEVOR_OIDC_SA` repo secret holding the IAM role ARN to assume.
- **OIDC trust policy** — the role's trust policy `sub` condition must match the *exact* claim GitHub sends. If the repo or your account was ever renamed, GitHub sends `repo:{owner}@{owner_id}/{repo}@{repo_id}:...` instead of the plain-name form — check CloudTrail (`AssumeRoleWithWebIdentity` events) if this mismatches. A job with an `environment:` key (like `terraform-apply`) sends `environment:<name>` instead of `ref:refs/heads/<branch>` — both forms need their own trust policy entry.
- **Identity provider audience** — the IAM OIDC identity provider for `token.actions.githubusercontent.com` needs `sts.amazonaws.com` in its Audience list, separately from the role's trust policy condition.
- **`TFPLAN_ENCRYPTION_KEY` secret** — passphrase used to symmetrically encrypt/decrypt the plan artifact between the plan and apply jobs.
- **Manual approval gate** — a `prod` GitHub Environment with required reviewers (needs a public repo, or GitHub Pro/Team/Enterprise for a private one, since environment protection rules aren't available for private repos on the Free plan).
- No app-secret GitHub Action secret is needed anymore — `secret_names` isn't sensitive, and no secret values are ever supplied via CI.

## Cost (approximate, ap-south-1, single-task setup)

| Resource | ~Monthly Cost (USD) |
|---|---|
| ECS Fargate (1 task, 0.5 vCPU/1GB) | $18 |
| ALB | $18–20 |
| EFS | $1 |
| Secrets Manager | $1 |
| CloudWatch Logs | $1 |
| ECR | $0.10 |
| Bedrock (Claude) | pay-per-token, not included above — see [Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) |
| Data transfer | $2–5 |

**Total (excluding Bedrock token usage): ~$40–47/month.** Cost knobs already wired up: `fargate_spot_weight`, `task_cpu`/`task_memory`, `desired_count`, `log_retention_in_days`, `container_insights_enabled`.

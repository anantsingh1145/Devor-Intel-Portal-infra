# terraform init -backend-config=environments/backend.hcl
bucket       = "devor-infra-state-file"
key          = "terraform.tfstate"
region       = "ap-south-1"
encrypt      = true
use_lockfile = true # native S3 state locking (Terraform >= 1.10), no DynamoDB table needed

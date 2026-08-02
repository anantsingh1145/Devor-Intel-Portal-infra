variable "name_prefix" {
  description = "Prefix used to name the IAM policy created by this module."
  type        = string
}

variable "task_role_name" {
  description = "Name of the ECS task role (from modules/iam) to attach Bedrock invoke permission to. The task itself calls Bedrock at runtime, not the execution role."
  type        = string
}

variable "aws_region" {
  description = "Region the inference profile lives in."
  type        = string
}

variable "inference_profile_id" {
  description = "Cross-region inference profile ID, e.g. \"apac.anthropic.claude-<model>-<date>-v<N>:0\". Verify the current value with `aws bedrock list-inference-profiles --region <region>` — do not assume this is still current."
  type        = string
}

variable "foundation_model_id" {
  description = "Base foundation model ID underlying var.inference_profile_id, without the geographic prefix, e.g. \"anthropic.claude-<model>-<date>-v<N>:0\". Required alongside the inference profile ARN because Bedrock may route the request to any region within the profile — omitting this causes AccessDeniedException. Verify with `aws bedrock list-foundation-models --region <region>`."
  type        = string
}

variable "tags" {
  description = "Tags applied to the IAM policy."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# -----------------------------------------------------------------------------
# Resources: s3-static-website/variables
# -----------------------------------------------------------------------------

variable "endpoint" {
  description = "Endpoint url"
  type        = string
  default     = "mystatic-website.bello.sg"
}

variable "bucket_name" {
  description = "My static website bucket"
  type        = string
  default     = "mystatic-website.bello.sg"
}


# -----------------------------------------------------------------------------
# Resources: CodePipeline/variables
# -----------------------------------------------------------------------------

variable "artifacts_bucket_name" {
    default = "myartifacts-bello-sg"
    description = "The name of the codepipeline artifacts bucket."
    type = string
}

variable "pipeline_name" {
  description = "CodePipeline name"
  type        = string
  default     = "s3-static-website-main-pipeline"
}

variable "codepipeline_role" {
  default     = "static-website-codepipeline-role"
  description = "The codepipeline role name"
  type        = string
}

variable "codepipeline_policy_name" {
  default     = "static-website-codepipeline-policy"
  description = "The pipeline policy name"
  type        = string
}

variable "github_owner" {
  description = "My static website bucket"
  type        = string
  default     = "bellotifang"
}

variable "github_repo_id" {
  default     = "bellotifang/s3-static-website"
  description = "The repository id"
  type        = string
}

variable "source_branch" {
  default     = "main"
  description = "The name of the github source branch"
  type        = string
}

variable "connection_arn" {
  description = "My static website bucket"
  type        = string
  default     = "arn:aws:codestar-connections:us-east-1:391598506975:connection/ab96f2be-a20a-45b1-a776-4f73e1ffbd07"
}

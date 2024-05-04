variable "soci_repository_image_tag_filters" {
  type        = list(string)
  default     = ["*:*"]
  description = "list of SOCI repository image tag filters. Default is `[\"*:*\"]`."
}

variable "deployment_assets_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for your copy of the deployment assets. This bucket is not created by this module. You must create it before deploying the module."
}
variable "deployment_assets_key_prefix" {
  type        = string
  default     = "cfn-ecr-aws-soci-index-builder/"
  description = "S3 key prefix used where to copy the deployment assets. Default is `cfn-ecr-aws-soci-index-builder/`"
}
variable "resource_prefix" {
  type        = string
  description = "Prefix for the AWS resources created by this module. Default is `ecr-soci-indexer`."
  default     = "ecr-soci-indexer"
}

variable "region" {
  type        = string
  description = "AWS region of the ECR where to deploy the SOCI index builder."
}
variable "account_id" {
  type        = string
  description = "AWS account ID where to deploy the SOCI index builder."
}

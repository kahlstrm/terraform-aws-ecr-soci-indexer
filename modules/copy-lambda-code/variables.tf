variable "region" {
  type        = string
  description = "AWS region of the ECR where to download the lambda codes from."
}
variable "deployment_assets_bucket" {
  type        = string
  description = "Name of the S3 bucket where to store the lambda codes. This bucket is not created by this module. You must create it before deploying the module."
}
variable "deployment_assets_key_prefix" {
  type        = string
  default     = "cfn-ecr-aws-soci-index-builder/"
  description = "S3 key prefix used where to copy the deployment assets. Default is `cfn-ecr-aws-soci-index-builder/`"
}

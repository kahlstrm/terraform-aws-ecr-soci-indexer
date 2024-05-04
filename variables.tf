variable "soci_repository_image_tag_filters" {
  type        = list(string)
  default     = ["*:*"]
  description = "list of SOCI repository image tag filters. Default is `[\"*:*\"]`."
}

variable "deployment_assets_bucket" {
  type        = string
  description = "Name of the S3 bucket where the files for. This bucket is not created by this module. You must create it before deploying the module."
}
variable "ecr_image_filter_lambda_asset_path" {
  type        = string
  description = "Path to the ECR image filter Lambda asset zip-file. Use the `copy-lambda-code` module to copy the asset to an S3 bucket."
}
variable "ecr_image_filter_lambda_handler" {
  type        = string
  default     = "ecr_image_action_event_filtering_lambda_function.lambda_handler"
  description = "Name of the handler function in the ECR image filter Lambda. Default is `ecr_image_action_event_filtering_lambda_function.lambda_handler`. Required if not using the `copy-lambda-code` module."
}
variable "ecr_image_filter_lambda_runtime" {
  type        = string
  default     = "python3.9"
  description = "Runtime of the ECR image filter Lambda. Default is `python3.9`. Required if not using the `copy-lambda-code` module."
}
variable "soci_index_generator_lambda_asset_path" {
  type        = string
  description = "Path to the SOCI index generator Lambda asset zip-file. Use the `copy-lambda-code` module to copy the asset to an S3 bucket."
}
variable "soci_index_generator_lambda_handler" {
  type        = string
  default     = "main"
  description = "Name of the handler function in the SOCI index generator Lambda. Default is `soci_index_generator_lambda_function.lambda_handler`. Required if not using the `copy-lambda-code` module."
}
variable "soci_index_generator_lambda_runtime" {
  type        = string
  default     = "provided.al2"
  description = "Runtime of the SOCI index generator Lambda. Default is `provided.al2`. Required if not using the `copy-lambda-code` module."
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

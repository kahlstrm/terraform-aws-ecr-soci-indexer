locals {
  ecr_image_action_event_filtering_lambda_object_path = "functions/packages/ecr-image-action-event-filtering/lambda.zip"
  soci_index_generator_lambda_object_path             = "functions/packages/soci-index-generator-lambda/soci_index_generator_lambda.zip"
  aws_quickstart_soci_indexer_prefix                  = "aws-quickstart-${var.region}/cfn-ecr-aws-soci-index-builder/"
}
# ECR image filtering lambda function package, from https://aws-ia.github.io/cfn-ecr-aws-soci-index-builder/
# source code available at https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder
resource "aws_s3_object_copy" "ecr_image_action_event_filtering_lambda_object" {
  bucket = var.deployment_assets_bucket
  key    = "${var.deployment_assets_key_prefix}${local.ecr_image_action_event_filtering_lambda_object_path}"
  source = "${local.aws_quickstart_soci_indexer_prefix}${local.ecr_image_action_event_filtering_lambda_object_path}"
}
# SOCI index generator lambda function package, from https://aws-ia.github.io/cfn-ecr-aws-soci-index-builder/
# source code available at https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder
resource "aws_s3_object_copy" "soci_index_generator_lambda_object" {
  bucket = var.deployment_assets_bucket
  key    = "${var.deployment_assets_key_prefix}${local.soci_index_generator_lambda_object_path}"
  source = "${local.aws_quickstart_soci_indexer_prefix}${local.soci_index_generator_lambda_object_path}"
}

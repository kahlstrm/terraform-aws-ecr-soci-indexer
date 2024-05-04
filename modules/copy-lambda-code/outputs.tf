output "asset_bucket" {
  value = var.deployment_assets_bucket
}

output "ecr_image_filter_lambda_asset_path" {
  value = aws_s3_object_copy.ecr_image_action_event_filtering_lambda_object.key
}

output "soci_index_generator_lambda_asset_path" {
  value = aws_s3_object_copy.soci_index_generator_lambda_object.key
}

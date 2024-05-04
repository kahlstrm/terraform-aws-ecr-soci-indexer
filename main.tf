locals {
  resource_prefix = var.resource_prefix != "" ? "${var.resource_prefix}-" : ""
}


resource "aws_lambda_function" "ecr_image_action_event_filtering" {
  function_name = "${local.resource_prefix}ECRImageActionEventFilter"
  handler       = var.ecr_image_filter_lambda_handler
  runtime       = var.ecr_image_filter_lambda_runtime
  role          = aws_iam_role.ecr_image_action_event_filtering.arn
  timeout       = 900
  logging_config {
    log_format = "Text"
  }
  s3_bucket = var.deployment_assets_bucket
  s3_key    = var.ecr_image_filter_lambda_asset_path
  environment {
    variables = {
      soci_repository_image_tag_filters = join(",", var.soci_repository_image_tag_filters)
      soci_index_generator_lambda_arn   = aws_lambda_function.soci_index_generator.arn
    }
  }
}

resource "aws_lambda_function" "soci_index_generator" {
  function_name = "${local.resource_prefix}SociIndexGenerator"
  handler       = var.ecr_image_filter_lambda_handler
  runtime       = var.soci_index_generator_lambda_runtime
  role          = aws_iam_role.soci_index_generator.arn
  timeout       = 900

  s3_bucket = var.deployment_assets_bucket
  s3_key    = var.soci_index_generator_lambda_asset_path
  ephemeral_storage {
    size = 10240 # 10GB
  }
  memory_size = 1024
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecr_image_action_event_filtering" {
  name               = "${local.resource_prefix}ECRImageEventFilterLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}


resource "aws_iam_policy" "ecr_image_action_event_filtering_lambda_invoke" {
  name   = "${local.resource_prefix}ECRImageEventFilterLambdaInvokePolicy"
  policy = data.aws_iam_policy_document.ecr_lambda_invoke_policy.json
}
data "aws_iam_policy_document" "ecr_lambda_invoke_policy" {
  statement {
    actions   = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = [aws_lambda_function.soci_index_generator.arn]
  }
}
resource "aws_iam_role_policy_attachment" "ecr_image_action_event_filtering_lambda_invoke" {
  role       = aws_iam_role.ecr_image_action_event_filtering.name
  policy_arn = aws_iam_policy.ecr_image_action_event_filtering_lambda_invoke.arn
}
resource "aws_cloudwatch_log_group" "ecr_image_action_event_filtering_lg" {
  name              = "/aws/lambda/${aws_lambda_function.ecr_image_action_event_filtering.function_name}"
  retention_in_days = 14
}
resource "aws_iam_policy" "ecr_image_action_event_filtering_lambda_cloudwatch" {
  name   = "${local.resource_prefix}ECRImageEventFilterLambdaLogPolicy"
  policy = data.aws_iam_policy_document.ecr_image_action_event_filtering_lambda_cloudwatch_policy.json
}
data "aws_iam_policy_document" "ecr_image_action_event_filtering_lambda_cloudwatch_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.ecr_image_action_event_filtering_lg.arn}:*"
    ]
  }
}
resource "aws_iam_role_policy_attachment" "ecr_image_action_event_filtering_lambda_cloudwatch" {
  role       = aws_iam_role.ecr_image_action_event_filtering.name
  policy_arn = aws_iam_policy.ecr_image_action_event_filtering_lambda_cloudwatch.arn
}

# SociIndexGeneratorLambda IAM Role
resource "aws_iam_role" "soci_index_generator" {
  name               = "${local.resource_prefix}SociIndexGeneratorLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_cloudwatch_log_group" "soci_index_generator_lg" {
  name              = "/aws/lambda/${aws_lambda_function.soci_index_generator.function_name}"
  retention_in_days = 14
}
resource "aws_iam_policy" "soci_index_generator_lambda_cloudwatch" {
  name   = "${local.resource_prefix}SOCIIndexGeneratorLambdaLogPolicy"
  policy = data.aws_iam_policy_document.soci_index_generator_lambda_cloudwatch_policy.json
}
data "aws_iam_policy_document" "soci_index_generator_lambda_cloudwatch_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.soci_index_generator_lg.arn}:*"
    ]
  }
}
resource "aws_iam_role_policy_attachment" "soci_index_generator_lambda_cloudwatch" {
  role       = aws_iam_role.soci_index_generator.name
  policy_arn = aws_iam_policy.soci_index_generator_lambda_cloudwatch.arn
}

# RepositoryNameParsingLambda IAM Role
resource "aws_iam_role" "repository_name_parsing_lambda" {
  name               = "${local.resource_prefix}RepositoryNameParsingLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
data "archive_file" "repository_name_parsing_lambda_zip_inline" {
  type        = "zip"
  output_path = "/tmp/repository_name_parsing_lambda_zip_inline.zip"
  source {
    content  = <<EOF
import json

def handler(event, context):
  filters = event['filters']
  REPO_PREFIX = 'arn:aws:ecr:${var.region}:${var.account_id}:repository/'
  repository_arns = []
  response = {}

  try:
    repositories = [filter.split(':')[0] for filter in filters]
    for repository in repositories:
      if repository == '*':
        repository_arns = [REPO_PREFIX + '*']
        break

      repository_arns.append(REPO_PREFIX + repository)

    response['repository_arns'] = repository_arns
    return {
      "statusCode": 200,
      "body": json.dumps(response)
    }
  except Exception:
    return {
      "statusCode": 500,
      "body": json.dumps(response)
    }
EOF
    filename = "index.py"
  }
}

# Lambda Function for Parsing Repository Names
resource "aws_lambda_function" "repository_name_parsing_lambda" {
  function_name = "${local.resource_prefix}RepositoryNameParsingLambda"
  handler       = "index.handler"
  runtime       = "python3.9"
  role          = aws_iam_role.repository_name_parsing_lambda.arn

  filename         = data.archive_file.repository_name_parsing_lambda_zip_inline.output_path
  source_code_hash = data.archive_file.repository_name_parsing_lambda_zip_inline.output_base64sha256

}

data "aws_lambda_invocation" "name_parsing_lambda" {
  function_name = aws_lambda_function.repository_name_parsing_lambda.function_name
  input = jsonencode({
    filters = var.soci_repository_image_tag_filters
  })
}


# ECR Repository Policy for SociIndexGeneratorLambda
resource "aws_iam_policy" "soci_index_generator_ecr_repository_policy" {
  name   = "${local.resource_prefix}SociIndexGeneratorLambdaECRPolicy"
  policy = data.aws_iam_policy_document.soci_index_generator_ecr_repository_policy.json
}

data "aws_iam_policy_document" "soci_index_generator_ecr_repository_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = jsondecode(jsondecode(data.aws_lambda_invocation.name_parsing_lambda.result)["body"])["repository_arns"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

# Attach ECR Policy to SociIndexGeneratorLambda Role
resource "aws_iam_role_policy_attachment" "soci_index_generator_ecr_repository" {
  role       = aws_iam_role.soci_index_generator.name
  policy_arn = aws_iam_policy.soci_index_generator_ecr_repository_policy.arn
}


# EventBridge Rule to trigger Lambda on ECR image push
resource "aws_cloudwatch_event_rule" "ecr_image_action_event" {
  name        = "${local.resource_prefix}ECRImageActionEventBridgeRule"
  description = "Invokes Amazon ECR image action event filtering Lambda function when image is successfully pushed to ECR."

  event_pattern = jsonencode({
    source        = ["aws.ecr"]
    "detail-type" = ["ECR Image Action"]
    detail = {
      action-type = ["PUSH"]
      result      = ["SUCCESS"]
    }
    region = [var.region]
  })

  state = "ENABLED"
}

# Target for the EventBridge Rule
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ecr_image_action_event.name
  target_id = "ecr-image-action-lambda-target"
  arn       = aws_lambda_function.ecr_image_action_event_filtering.arn
}

# Permission for EventBridge to invoke the Lambda function
resource "aws_lambda_permission" "allow_event_bridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecr_image_action_event_filtering.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_image_action_event.arn
}

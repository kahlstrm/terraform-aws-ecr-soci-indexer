# AWS SOCI Index Builder Module

This Terraform module automates the generation of Seekable OCI (SOCI) index artifacts and manages their storage in Amazon ECR. It is designed to ease the adoption of SOCI technology by automating the creation of SOCI indices triggered by image pushes to designated ECR repositories. SOCI indices are used to optimize the performance of container image pulls by enabling the Docker client to seek directly to the layers it needs, rather than downloading the entire image.

This is a terraform version of [CFN AWS SOCI Index Builder on AWS
Partner Solution Deployment Guide](https://aws-ia.github.io/cfn-ecr-aws-soci-index-builder/) and the lambdas deployed by this solution are the same as the ones deployed by the CloudFormation template.

## Features

- **ECR Event Handling**: Automatically triggers Lambda functions to generate SOCI index artifacts upon new image pushes to ECR.
- **IAM Role Management**: Configures IAM roles with precise permissions necessary for operations.
- **S3 Integration**: Utilizes S3 for storing Lambda function code and related assets. Currently, the module does not create the S3 bucket, so you must provide an existing bucket. The bucket is where the Lambda function codes are stored.

## Usage

Using it with the Lambda code provided by the AWS IA-team:

```hcl

// Copy the Lambda code FROM AWS-IA bucket to own S3 bucket
module "copy_lambda_code" {
  source                       = "kahlstrm/ecr-soci-indexer/aws//modules/copy-lambda-code"
  deployment_assets_bucket     = "my-soci-index-assets-bucket" // needs to be created before running this module
  region                       = "us-east-1"
  deployment_assets_key_prefix = "path/to/my/artifacts/" // optional, defaults to "cfn-ecr-aws-soci-index-builder/"
}
module "soci_index_builder" {
  source                                 = "kahlstrm/ecr-soci-indexer/aws"
  deployment_assets_bucket               = module.copy_lambda_code.asset_bucket
  ecr_image_filter_lambda_asset_path     = module.copy_lambda_code.ecr_image_filter_lambda_asset_path
  soci_index_generator_lambda_asset_path = module.copy_lambda_code.soci_index_generator_lambda_asset_path
  region                                 = "us-east-1"
  account_id                             = "123456789012"
  soci_repository_image_tag_filters      = ["repo1:tag1", "repo2:*"] // optional defaults to matching all tags in all repositories (`["*:*"]`)
  resource_prefix                        = "my-soci-indexer"         // optional, defaults to "ecr-soci-indexer".
}
```

Using it with your own Lambda code:

```hcl
module "soci_index_builder" {
  source                                 = "kahlstrm/ecr-soci-indexer/aws"
  deployment_assets_bucket               = "bucket-name"
  ecr_image_filter_lambda_asset_path     = "path/to/your/ecr-image-filter.zip" // NOTE: needs to be inside the "deployment_assets_bucket" bucket
  ecr_image_filter_lambda_handler        = "ecr_image_action_event_filtering_lambda_function.lambda_handler" // optional, defaults to "ecr_image_action_event_filtering_lambda_function.lambda_handler" (the handler in the provided lambda code)
  ecr_image_filter_lambda_runtime        = "python3.9" // optional, defaults to "python3.9" (the runtime in the provided lambda code)
  soci_index_generator_lambda_asset_path = "path/to/your/soci-index-generator.zip" // NOTE: needs to be inside the "deployment_assets_bucket" bucket
  soci_index_generator_lambda_handler    = "main" // optional, defaults to "main" (the handler in the provided lambda code)
  soci_index_generator_lambda_runtime    = "provided.al2" // optional, defaults to "provided.al2" (the runtime in the provided lambda code)
  region                                 = "us-east-1"
  account_id                             = "123456789012"
  soci_repository_image_tag_filters      = ["repo1:tag1", "repo2:*"] // optional defaults to matching all tags in all repositories (`["*:*"]`)
  resource_prefix                        = "my-soci-indexer"         // optional, defaults to "ecr-soci-indexer".
}
```

## Requirements

| Name                                | Version (tested on) |
| ----------------------------------- | ------------------- |
| [terraform](#requirement_terraform) | >= 1.8.2            |
| [aws](#requirement_aws)             | >= 5.46             |

## Providers

| Name                 | Version (tested on) |
| -------------------- | ------------------- |
| [aws](#provider_aws) | >= 5.46             |

## Authors

The module is maintained by [Kalle Ahlström](https://github.com/kahlstrm) with Lambda code from the [AWS SOCI Index Builder](https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder/). Contributions are welcome!

## License

Apache 2.0 Licensed. See [LICENSE](https://github.com/kahlstrm/terraform-aws-ecr-soci-indexer/blob/main/LICENSE) for full details.

## Disclaimer

### External Lambda Code Sources

This module configures AWS Lambda functions using code packages that are stored in Amazon S3. Users of this module should be aware that the Lambda code is developed and maintained outside of this Terraform module. While the module ensures that the right permissions and infrastructure settings are applied, the responsibility for the functionality, security, and maintenance of the Lambda code itself lies with the external developers. The external Lambda code is managed by the [AWS IA-team](https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder)

#### Considerations:

- **Code Origin**: Before using this module, verify the origin and integrity of the Lambda code packages. Ensure they come from a trusted and secure source.
- **Security Practices**: Regularly review and update the Lambda code to patch vulnerabilities, apply security best practices, and comply with your organization's compliance requirements.
- **Functionality Guarantees**: As the Lambda code is managed externally, any changes made to the code source might affect the behavior of the deployed infrastructure without prior notice within this module.

### Using Your Own Lambda Code

If you choose to use your own Lambda code, ensure that it meets the requirements and functionality expected by the module. The Lambda code must be compatible with the module's configuration and the AWS services it interacts with. The responsibility for the security, functionality, and maintenance of the Lambda code lies with the user. Good place to start is the [Reference Lambda code](https://github.com/aws-ia/cfn-ecr-aws-soci-index-builder/tree/main/functions/source) provided by the AWS IA-team.

We encourage users to fully understand the implications of using externally sourced code and to implement appropriate governance and security measures.

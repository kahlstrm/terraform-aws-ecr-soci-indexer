## `copy-lambda-code` module

This module copies the lambda codes from the AWS IA teams account to the destination bucket. Used together with the root module.

## Usage

```hcl
module "copy_lambda_code" {
  source                       = "kahlstrm/ecr-soci-indexer/aws//modules/copy-lambda-code"
  deployment_assets_bucket     = "my-soci-index-assets-bucket" // needs to be created before running this module
  region                       = "us-east-1"
  deployment_assets_key_prefix = "path/to/my/artifacts/" // optional, defaults to "cfn-ecr-aws-soci-index-builder/"
}
```

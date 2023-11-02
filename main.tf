terraform {
  required_version = ">= 1.6.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.23.1"
    }
  }
}

variable "aws_region" {
  type    = map
  default = {
    dev = "us-east-1"
    prod = "eu-west-2"
  }
}

provider "aws" {
  region = var.aws_region[terraform.workspace]
}

data "archive_file" "myzip" {
  type        = "zip"
  source_file = "main.py"
  output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
  filename         = "main.zip"
  function_name    = "mypython_lambda_test_${terraform.workspace}"
  role             = aws_iam_role.mypython_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = "data.archive_file.myzip.output_base64sha256"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "mypython_lambda_role" {
  name               = "mypython_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

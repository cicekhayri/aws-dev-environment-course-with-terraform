terraform {
#   required_version = ">= 0.12"
  required_version = ">= 1.6.2"
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.23.1"
    }
  }
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

data "archive_file" "myzip" {
    type = "zip"
    source_file = "main.py"
    output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
  filename = "main.zip"
  function_name = "mypython_lambda_test"
  role = aws_iam_role.mypython_lambda_role.arn
  handler = "main.lambda_handler"
  runtime = "python3.11"
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

resource "aws_sqs_queue" "main_queue" {
  name = "my-main-queue"
  delay_seconds = 30
  max_message_size = 262144
}

resource "aws_sqs_queue" "dlq_queue" {
  name = "my-dlq-queue"
  delay_seconds = 30
  max_message_size = 262144
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.5"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  bucket_name = "${var.bucket_name}-${data.aws_caller_identity.current.account_id}"
  region = data.aws_region.current.name
}

resource "aws_s3_bucket" "tfstate_bucket" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.bucket_name
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = local.bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = local.bucket_name

  rule {
    id = "log"

    expiration {
      days = 10
    }

    filter {
      and {
        prefix = "terraform/state/"

        tags = {
          rule      = "log"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"

  }
  depends_on = [ aws_s3_bucket.tfstate_bucket, aws_s3_bucket_versioning.versioning_example ]
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "tfstate-s3-bucket"
}

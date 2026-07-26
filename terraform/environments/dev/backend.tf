terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Fill in with the bucket/table names created by terraform/bootstrap,
  # or pass them via -backend-config at `terraform init` time. See
  # docs/DEPLOYMENT.md for the exact commands.
  backend "s3" {
    bucket         = "REPLACE_ME_bluepeak-tf-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bluepeak-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

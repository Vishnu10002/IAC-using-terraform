# Terraform Settings Block
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.44"
     }
  }
}

# Terraform Provider Block
provider "aws" {
  region = var.aws_region
  access_key = "AKIAWYIXSUURDT2XRDO3"
  secret_key = "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"
  
}
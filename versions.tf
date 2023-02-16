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
 
  
}

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

################################################################################
# Common Locals
################################################################################

locals {
  name = "irsa-v2-resources"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/clowdhaus/terraform-aws-irsa-v2"
  }
}

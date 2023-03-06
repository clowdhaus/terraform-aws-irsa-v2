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
  name = "irsav2-SCMA-cluster"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Repository = "https://github.com/clowdhaus/terraform-aws-irsa-v2"
  }
}

################################################################################
# Common Data
################################################################################

data "aws_availability_zones" "available" {}

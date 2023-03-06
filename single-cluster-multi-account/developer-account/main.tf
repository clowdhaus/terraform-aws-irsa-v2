provider "aws" {
  region = local.region
}

locals {
  region = "us-west-2"
  name   = "irsa-v2-SCMA-developer"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/clowdhaus/terraform-aws-irsa-v2"
  }
}

################################################################################
# IRSA v2 Module
################################################################################

module "irsa_v2" {
  source = "../../.."

  create = false

  tags = local.tags
}

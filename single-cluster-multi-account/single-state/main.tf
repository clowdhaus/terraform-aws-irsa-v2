provider "aws" {
  region = local.region
}

provider "aws" {
  region = local.region2
  alias  = "region2"
}

locals {
  region  = "us-west-2"
  region2 = "us-east-1"

  name = "irsa-v2-SCMA-single"

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

################################################################################
# IRSA v2
################################################################################

module "dev1_irsa" {
  # source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "~> 6.0"
  source = "github.com/clowdhaus/terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "dev1-irsa"

  enable_irsa_v2 = true
  role_policy_arns = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  tags = local.tags
}

################################################################################
# IRSA v2
################################################################################

module "ebs_csi" {
  # source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "~> 6.0"
  source = "github.com/clowdhaus/terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "ebs-csi-irsa"

  enable_irsa_v2        = true
  attach_ebs_csi_policy = true

  tags = local.tags
}

module "vpc_cni" {
  # source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "~> 6.0"
  source = "github.com/clowdhaus/terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "vpc-cni-ipv4-irsa"

  enable_irsa_v2        = true
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  tags = local.tags
}

module "karpenter" {
  # source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "~> 6.0"
  source = "github.com/clowdhaus/terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "karpenter-irsa"

  enable_irsa_v2          = true
  attach_karpenter_policy = true

  # TODO - this is tied to one cluster; how to accommodate multiple clusters?
  karpenter_cluster_name       = module.eks_direct.cluster_name
  karpenter_node_iam_role_arns = [module.eks_direct.eks_managed_node_groups["default"].iam_role_arn]

  tags = local.tags
}

module "app" {
  # source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  # version = "~> 6.0"
  source = "github.com/clowdhaus/terraform-aws-iam/modules/iam-role-for-service-accounts"

  name = "app-irsa"

  enable_irsa_v2 = true
  role_policy_arns = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }

  tags = local.tags
}

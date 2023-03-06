data "aws_iam_role" "this" {
  for_each = toset([
    "ebs-csi-irsa",
    "vpc-cni-ipv4-irsa",
    "karpenter-irsa", # Warning - this is tied to one cluster; how to accommodate multiple clusters?
    "app-irsa",
  ])

  name = each.value
}

module "eks_indirect" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  cluster_name    = local.name
  cluster_version = "1.25"

  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = data.aws_iam_role.this["ebs-csi-irsa"].arn
    }
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      service_account_role_arn = data.aws_iam_role.this["vpc-cni-ipv4-irsa"].arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = ["m6i.large"]

      min_size     = 2
      max_size     = 5
      desired_size = 2
    }
  }

  ################################################################################
  # This does not exist today - psuedo code only

  role_associations = {
    karpenter = {
      role_arn        = data.aws_iam_role.this["karpenter-irsa"].arn
      namespace       = "karpenter"
      service_account = "karpenter"
    }

    app = {
      role_arn        = data.aws_iam_role.this["app-irsa"].arn
      namespace       = "app"
      service_account = "app1"
    }
  }
  ################################################################################

  tags = local.tags
}

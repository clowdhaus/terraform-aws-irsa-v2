module "eks_direct" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  cluster_name    = local.name
  cluster_version = "1.25"

  # EKS Addons
  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.ebs_csi_irsa.arn
    }
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      service_account_role_arn = module.vpc_cni_irsa.arn
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
  # This does not exist today - pseudo code only

  role_associations = {
    karpenter = {
      role_arn        = module.karpenter_irsa.arn
      namespace       = "karpenter"
      service_account = "karpenter"
    }

    app = {
      role_arn        = module.app_irsa.arn
      namespace       = "app"
      service_account = "app1"
    }
  }
  ################################################################################

  tags = local.tags
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-west-2"
  alias  = "usw2"
}

provider "aws" {
  region = "us-west-2"
  alias  = "acct2_usw2"

  assume_role {
    role_arn     = "arn:aws:iam::222222222222:role/terraform-role"
    session_name = "terraform"
  }
}

################################################################################
# EKS Clusters
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks"
  version = "~> 19.10"

  # Cluster in same account and region as current Terraform configuration
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

  # ... other configuration ...
}

module "eks_usw2" {
  source  = "terraform-aws-modules/eks"
  version = "~> 19.10"

  # Cluster in same account but different region from the current Terraform configuration
  providers = {
    aws = aws.usw2
  }

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

  # ... other configuration ...
}

module "eks_acct2_usw2" {
  source  = "terraform-aws-modules/eks"
  version = "~> 19.10"

  # Cluster in different account and region from the current Terraform configuration
  providers = {
    aws = aws.acct2_usw2
  }

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

  # ... other configuration ...
}

################################################################################
# IRSA v1
################################################################################

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
    eks_usw2 = {
      provider_arn               = module.eks_usw2.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
    # Possible, but not pragmatic
    eks_acct2_usw2 = {
      provider_arn               = module.eks_acct2_usw2.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "vpc-cni-ipv4"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
    eks_usw2 = {
      provider_arn               = module.eks_usw2.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
    # Possible, but not pragmatic
    eks_acct2_usw2 = {
      provider_arn               = module.eks_acct2_usw2.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}

# Role is in same account and region as cluster
module "karpenter_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                          = "karpenter-controller"
  attach_karpenter_controller_policy = true

  # Currently tied to a single cluster
  karpenter_controller_cluster_id         = module.eks.cluster_name
  karpenter_controller_node_iam_role_arns = [module.eks.eks_managed_node_groups["default"].iam_role_arn]

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
    # Currently tied to a single cluster
  }
}

# Role is in developer account with access to resources local to the account,
# cluster is in a different account
module "app_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  # Cluster in different account and region from the current Terraform configuration
  providers = {
    aws = aws.acct2_usw2
  }

  role_name = "app"

  oidc_providers = {
    eks_acct2_usw2 = {
      provider_arn               = module.eks_acct2_usw2.oidc_provider_arn
      namespace_service_accounts = ["app:app1", "canary:app1"]
    }
  }

  role_policy_arns = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }
}

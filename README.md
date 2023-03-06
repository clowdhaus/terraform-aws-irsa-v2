# AWS IRSA v2 Terraform Usage

Demonstrates different usage patterns for IAM roles for service accounts v2.

## Comparison

### IRSA v1

```hcl
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
```

### IRSA v2

```hcl
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

  role_associations = {
    karpenter = {
      role_arn        = module.karpenter_irsa_role.role_arn
      namespace       = "karpenter"
      service_account = "karpenter"
    }

    app = {
      role_arn        = module.app_irsa_role.role_arn
      namespace       = "app"
      service_account = "app1"
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

  role_associations = {
    karpenter = {
      role_arn        = module.karpenter_irsa_role.role_arn
      namespace       = "karpenter"
      service_account = "karpenter"
    }

    app = {
      role_arn        = module.app_irsa_role.role_arn
      namespace       = "app"
      service_account = "app1"
    }
  }

  # ... other configuration ...
}

module "eks_acct2_usw2" {
  source  = "terraform-aws-modules/eks"
  version = "~> 19.10"

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

  # Cluster in different account and region from the current Terraform configuration
  providers = {
    aws = aws.acct2_usw2
  }

  # ... other configuration ...
}

################################################################################
# IRSA v2
################################################################################

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi"
  attach_ebs_csi_policy = true
}

module "vpc_cni_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "vpc-cni-ipv4"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true
}

module "karpenter_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                          = "karpenter-controller"
  attach_karpenter_controller_policy = true

  # # TODO - how to decouple from a cluster and make generic across clusters?
  # karpenter_controller_cluster_id         = module.eks.cluster_name
  # karpenter_controller_node_iam_role_arns = [module.eks.eks_managed_node_groups["default"].iam_role_arn]

  tags = local.tags
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

  # TODO - ???

  role_policy_arns = {
    CloudWatchLogsFullAccess = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  }
}

```

## License

Apache-2.0 Licensed. See [LICENSE](https://github.com/clowdhaus/terraform-aws-irsa-v2/blob/main/LICENSE).

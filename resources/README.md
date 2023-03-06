# Resources

⚠️ This example is only a representation of what IRSAv2 might look like from a Terraform perspective. The code is curently not functional and is only intended to demonstrate the concept.

This example demonstrates what the underlying Terraform resources might look like for IRSAv2.

## IAM Role

The IAM role trusts the EKS service endpoint of `eks-pods.amazonaws.com` (subjet to change). The EKS service assumes the role and provides permissions to the pod(s) that are running in the namespace(s) and service account(s) associated with the IAM role (see role association below). The trust policy shown below replaces the federated OIDC trust policy used by IRSAv1:

```hcl
resource "aws_iam_role" "team1" {
  name_prefix = "team1-"
  description = "Team1 example IAM role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # Subject to change
          Service = "eks-pods.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Environment = "dev"
  }
}
```

## Cluster IAM Role Association

The cluster IAM role association associates the IAM role with the specified namespace(s) and service accounts wihtin the provided EKS cluster. In IRSAv1, the role was assigned to the pod(s) via Kubernetes annotations; in IRSAv2 this assignment is made via the EKS API using the role association. Any pods that are created in the specified namespace(s) and service account(s) will inherit the permissions provided by the role.

```hcl
# Associate with the development cluster
resource "aws_eks_cluster_role_association" "team1_dev1" {
  role_arn    = aws_iam_role.team1.arn
  cluster_arn = aws_eks_cluster.dev1.arn

  namespace       = "default"
  service_account = "default"
}

# Associate with the QA cluster
resource "aws_eks_cluster_role_association" "team1_qa1" {
  role_arn    = aws_iam_role.team1.arn
  cluster_arn = aws_eks_cluster.qa1.arn

  namespace       = "team1"
  service_account = "app1"
}
```

## Module Implementation

An example of what this resource's implementation might look like within the [`terraform-aws-eks` module](https://github.com/terraform-aws-modules/terraform-aws-eks) is shown below. Users can specify zero or more role associations within the `cluster_role_association` block. The `cluster_role_association` block is a list of objects that contain the following attributes:

  - `role_arn` - (Required) The ARN of the IAM role to associate with the EKS cluster.
  - `cluster_arn` - (Required) The ARN of the EKS cluster to associate the IAM role with.
  - `namespace` - (Required) The name of the namespace to associate the IAM role with.
  - `service_account` - (Required) The service account to associate the IAM role with.

```hcl
resource "aws_eks_cluster_role_association" "this" {
  for_each = var.role_associations

  role_arn    = each.value.role_arn
  cluster_arn = aws_eks_cluster.this[0].arn

  namespace       = each.value.namespace
  service_account = each.value.service_account
}
```

This looks like the following in practice within the [`terraform-aws-eks` module](https://github.com/terraform-aws-modules/terraform-aws-eks):

```hcl
module "eks_direct" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.10"

  # ... other configuration ...

  # IRSAv2
  role_associations = {
    karpenter = {
      role_arn = module.karpenter_irsa.arn
      namespace =     = "karpenter"
      service_account = "karpenter"
    }

    app = {
      role_arn = module.app_irsa.arn
      namespace       = "app"
      service_account = "app1"
    }
  }
}
```

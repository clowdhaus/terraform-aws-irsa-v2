
################################################################################
# IAM Role
################################################################################

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
          Service = "eks-pods.amazonaws.com"
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "team1" {
  role       = aws_iam_role.team1.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

################################################################################
# EKS Cluster Role Association
# Note: This does not exist today - psuedo code only
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_role_association
################################################################################

resource "aws_eks_cluster_role_association" "team1_dev1" {
  role_arn    = aws_iam_role.team1.arn
  cluster_arn = aws_eks_cluster.dev1.arn

  namespace        = "default"
  service_accounts = "default"
}

resource "aws_eks_cluster_role_association" "team1_qa1" {
  role_arn    = aws_iam_role.team1.arn
  cluster_arn = aws_eks_cluster.qa1.arn

  namespace       = "team1"
  service_account = "app1"
}

# Generic over 0 or more role associations
resource "aws_eks_cluster_role_association" "this" {
  for_each = var.role_associations

  role_arn    = each.value.role_arn
  cluster_arn = aws_eks_cluster.this[0].arn

  namespace       = each.value.namespace
  service_account = each.value.service_account
}

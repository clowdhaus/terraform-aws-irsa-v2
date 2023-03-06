# Single Cluster / Single Account Example

⚠️ This example is only a representation of what IRSAv2 might look like from a Terraform perspective. The code is curently not functional and is only intended to demonstrate the concept.

This example demonstrates how IRSAv2 might look like when associating roles from the same account to a single cluster. There are two cluster definitions shown in this example, but the pattern is still the same - IAM roles to a single cluster from the same account are mapped. The difference between the two cluster definitions is merely just demonstrating the two different ways users might associate roles:

1. Directcly (`eks_direct.tf`) - The IAM roles are created in the same Terraform statefile/workspace and mapped directly into the EKS cluster role association map. In this scenario, cluster creators are also responsible for creating the IAM roles and associating them to the cluster. An example of what this might look like from a repository layout:

    ```
    eks-infra/
    ├── dev-acct/
    |   ├── eks.tf
    |   └── irsa.tf
    └── prod-acct/
        ├── eks.tf
        └── irsa.tf
    ```

2. Indirectly (`eks_indirect.tf`) - The IAM roles are created in a separate Terraform statefile/workspace and mapped into the EKS cluster role association map by first looking up the roles using a data source. In this scenario, cluster creators may or may not be responsible for creating the IAM roles; they may be created by a separate team or perhaps managed in a separate repository. In this scenario, the `irsa.tf` would not exist here, but would be in the repository where the IAM roles are created. Two examples of what this might look like from a repository layout:

    Same repository:
    ```
    infra/
    ├── dev-acct/
    |    ├── eks/
    |    |    └── eks.tf
    |    └── iam/
    |         └── irsa.tf
    └── prod-acct/
          ├── eks/
          |    └── eks.tf
          └── iam/
              └── irsa.tf
    ```

    Separate repository:
    ```
    eks-infra/
    ├── dev-acct/
    |    └── eks.tf
    └── prod-acct/
          └── eks.tf

    iam/
    ├── dev-acct/
    |    └── irsa.tf
    └── prod-acct/
          └── irsa.tf
    ```

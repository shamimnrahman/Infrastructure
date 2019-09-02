resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.eks_worker.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML

    mapUsers = <<YAML
    - userarn: arn:aws:iam::815667184744:user/brian.baker
      username: brian.baker
      groups:
        - system:masters
    - userarn: arn:aws:iam::815667184744:user/paul.bonser
      username: paul.bonser
      groups:
        - system:masters
    - userarn: arn:aws:iam::815667184744:user/circleci.builder
      username: circleci.builder
      groups:
        - system:masters
YAML
  }
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_worker.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      env:
      - name: "AWS_PROFILE"
        value: "${var.aws_profile}"
      args:
        - "token"
        - "-i"
        - "${var.env}"
KUBECONFIG
}

output "cluster_endpoint" {
  description = "Endpoint URL to connect to the EKS cluster."
  value       = "${aws_eks_cluster.cluster.endpoint}"
}

output "cluster_ca_cert" {
  description = "Cluster CA certificate for use in authenticating the cluster server."
  value       = "${aws_eks_cluster.cluster.certificate_authority.0.data}"
  sensitive   = true
}

output "kubeconfig" {
  description = "Content which can be used in ~/.kube/config to connect to the cluster."
  value       = "${local.kubeconfig}"
  sensitive   = true
}

output "eks_worker_iam_role_name" {
  description = "Name of the IAM role for the EKS worker nodes, for adding extra policies to the role."
  value       = "${aws_iam_role.eks_worker.name}"
}

output "eks_worker_security_group_id" {
  description = "ID of the EKS Worker security group, for adding ingress rules elsewhere."
  value       = "${aws_security_group.eks_worker.id}"
}

output "vpc_id" {
  value = "${data.terraform_remote_state.vpc.vpc_id}"
}

terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config {
    region       = "${var.tfstate_region}"
    bucket       = "${var.tfstate_bucket}"
    key          = "${var.env}/eks/terraform.tfstate"
    profile      = "${var.aws_profile}"
    dynodb_table = "${var.tfstate_lock_table}"
  }
}

provider "k8s" {
  kubeconfig_content = "${data.terraform_remote_state.eks.kubeconfig}"
}

resource "aws_iam_policy" "ingress" {
  name        = "${var.env}-alb-ingress-policy"
  description = "Provide permissions to allow aws-alb-ingress-controller to work for the ${var.env} cluster."
  policy      = "${file("${path.module}/alb-ingress-policy.json")}"
}

// Provides needed aws-alb-ingress-controller permissions.
resource "aws_iam_role_policy_attachment" "eks_worker_alb_ingress" {
  policy_arn = "${aws_iam_policy.ingress.arn}"
  role       = "${data.terraform_remote_state.eks.eks_worker_iam_role_name}"
}

resource "aws_security_group" "alb" {
  name        = "${var.env}-ingress-alb"
  description = "Shared security group to allow incoming connections to ALBs and from ALBs to workers."
  vpc_id      = "${data.terraform_remote_state.eks.vpc_id}"

  ingress {
    description = "Allow all incoming HTTP traffic"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all incoming HTTPS traffic"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outgoing traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.env}-ingress-alb",
     "Environment", "${var.env}",
     "kubernetes.io/cluster/${var.env}", "owned",
    )
  }"
}

// Add a rule to the worker security group to allow all incoming traffic from the ingress ALBs
resource "aws_security_group_rule" "eks_worker_ingress_alb" {
  description              = "Allow ALBs to send all traffic"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  security_group_id        = "${data.terraform_remote_state.eks.eks_worker_security_group_id}"
  source_security_group_id = "${aws_security_group.alb.id}"
  type                     = "ingress"
}

# Manifests based on https://github.com/kubernetes-sigs/aws-alb-ingress-controller/tree/master/examples
data "template_file" "deployment" {
  template = "${file("${path.module}/k8s-manifests/deployment.yaml.tpl")}"

  vars {
    cluster_name = "${var.env}"
    aws_region   = "${var.aws_region}"
  }
}

resource "k8s_manifest" "service_account" {
  content = "${file("${path.module}/k8s-manifests/service-account.yaml")}"
}

resource "k8s_manifest" "cluster_role" {
  content = "${file("${path.module}/k8s-manifests/cluster-role.yaml")}"
}

resource "k8s_manifest" "cluster_role_binding" {
  content    = "${file("${path.module}/k8s-manifests/cluster-role-binding.yaml")}"
  depends_on = ["k8s_manifest.service_account", "k8s_manifest.cluster_role"]
}

resource "k8s_manifest" "deployment" {
  content    = "${data.template_file.deployment.rendered}"
  depends_on = ["k8s_manifest.cluster_role_binding"]
}

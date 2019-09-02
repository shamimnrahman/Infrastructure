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

resource "k8s_manifest" "service_account" {
  content = "${file("${path.module}/k8s-manifests/service-account.yaml")}"
}

resource "k8s_manifest" "cluster_role_binding" {
  content    = "${file("${path.module}/k8s-manifests/cluster-role-binding.yaml")}"
  depends_on = ["k8s_manifest.service_account"]
}

resource "k8s_manifest" "deployment" {
  content    = "${file("${path.module}/k8s-manifests/deployment.yaml")}"
  depends_on = ["k8s_manifest.cluster_role_binding"]
}

resource "k8s_manifest" "service" {
  content = "${file("${path.module}/k8s-manifests/deployment.yaml")}"
}

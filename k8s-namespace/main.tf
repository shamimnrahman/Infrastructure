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

data "external" "auth_token" {
  program = ["bash", "${path.module}/../eks/scripts/auth-token.sh"]

  query {
    cluster_name = "${var.env}"
  }
}

provider "kubernetes" {
  host                   = "${data.terraform_remote_state.eks.cluster_endpoint}"
  cluster_ca_certificate = "${base64decode(data.terraform_remote_state.eks.cluster_ca_cert)}"
  token                  = "${data.external.auth_token.result.token}"
  load_config_file       = false
}

locals {
  name = "${var.namespace_prefix}-${var.env}"
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "${local.name}"
  }
}

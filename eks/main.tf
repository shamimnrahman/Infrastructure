terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

data "external" "auth_token" {
  program = ["bash", "${path.module}/scripts/auth-token.sh"]

  query {
    cluster_name = "${aws_eks_cluster.cluster.name}"
  }
}

provider "kubernetes" {
  host                   = "${aws_eks_cluster.cluster.endpoint}"
  cluster_ca_certificate = "${base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)}"
  token                  = "${data.external.auth_token.result.token}"
  load_config_file       = false
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    region       = "${var.tfstate_region}"
    bucket       = "${var.tfstate_bucket}"
    key          = "${var.env}/vpc/terraform.tfstate"
    profile      = "${var.aws_profile}"
    dynodb_table = "${var.tfstate_lock_table}"
  }
}

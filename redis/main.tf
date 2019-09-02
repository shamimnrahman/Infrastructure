terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
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

resource "aws_security_group" "this" {
  name        = "${var.env}-${var.name}-redis"
  description = "${var.env} ${var.name} Redis Security Group"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    description     = "Allow ${var.env} EKS workers to access ${var.name} Redis"
    protocol        = "tcp"
    from_port       = "${var.port}"
    to_port         = "${var.port}"
    security_groups = ["${data.terraform_remote_state.eks.eks_worker_security_group_id}"]
  }

  tags = "${
    map(
      "Name", "${var.env} ${var.name} Redis Security Group",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "${var.env}-${var.name}"
  replication_group_description = "${var.name} Redis cluster for the ${var.env} environment"
  node_type                     = "${var.node_type}"
  port                          = "${var.port}"
  automatic_failover_enabled    = "${var.automatic_failover_enabled}"

  subnet_group_name  = "${data.terraform_remote_state.vpc.elasticache_subnet_group_name}"
  security_group_ids = ["${aws_security_group.this.id}"]

  engine                     = "redis"
  engine_version             = "4.0.10"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  number_cache_clusters = "${var.replicas_per_node_group}"

  // Disabling cluster_mode for now because it requires a separate library to support
  /* cluster_mode {
    replicas_per_node_group = "${var.replicas_per_node_group}"
    num_node_groups         = "${var.num_node_groups}"
  } */

  tags = "${
    map(
      "Name", "${var.env} ${var.name} Redis",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

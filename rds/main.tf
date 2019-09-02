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

resource "random_string" "password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" // Default minus "@" since that's not allowed in RDS passwords
}

resource "aws_security_group" "this" {
  name        = "${var.env}-${var.name}-${var.engine}"
  description = "${var.env} ${var.name} ${var.engine} Security Group"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  ingress {
    description     = "Allow ${var.env} EKS workers to access ${var.name} ${var.engine}"
    protocol        = "tcp"
    from_port       = "${var.port}"
    to_port         = "${var.port}"
    security_groups = ["${data.terraform_remote_state.eks.eks_worker_security_group_id}"]
  }

  tags = "${
    map(
      "Name", "${var.env} ${var.name} ${var.engine} Security Group",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

resource "aws_db_parameter_group" "this" {
  name        = "${var.env}-${var.name}-${var.engine}"
  family      = "${var.parameter_group_family}"
  description = "${var.env} ${var.name} ${var.engine} Parameter Group"

  parameter {
    name  = "rds.force_ssl"
    value = "${var.force_ssl}"
  }

  tags = "${
    map(
      "Name", "${var.env} ${var.name} ${var.engine} Parameter Group",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

resource "aws_db_instance" "this" {
  identifier              = "${var.env}-${var.name}-${var.engine}"
  name                    = "${var.db_name}"
  allocated_storage       = "${var.allocated_storage}"
  storage_type            = "${var.storage_type}"
  engine                  = "${var.engine}"
  engine_version          = "${var.engine_version}"
  instance_class          = "${var.instance_class}"
  username                = "${var.username}"
  password                = "${random_string.password.result}"
  backup_retention_period = "${var.backup_retention_period}"
  multi_az                = "${var.multi_az}"
  storage_encrypted       = true

  db_subnet_group_name   = "${data.terraform_remote_state.vpc.db_subnet_group_name}"
  vpc_security_group_ids = ["${aws_security_group.this.id}"]

  tags = "${
    map(
      "Name", "${var.env} ${var.name} ${var.engine} DB",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

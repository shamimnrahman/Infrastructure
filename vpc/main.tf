terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

locals {
  private_cidr_block     = "${cidrsubnet(var.vpc_cidr_block, 2, 0)}"
  public_cidr_block      = "${cidrsubnet(var.vpc_cidr_block, 2, 1)}"
  other_cidr_block       = "${cidrsubnet(var.vpc_cidr_block, 2, 3)}"
  elasticache_cidr_block = "${cidrsubnet(local.other_cidr_block, 2, 0)}"
  db_cidr_block          = "${cidrsubnet(local.other_cidr_block, 2, 1)}"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "1.40.0"

  name = "${var.env}-vpc"
  cidr = "${var.vpc_cidr_block}"

  azs = ["${data.aws_availability_zones.available.names}"]

  private_subnets = [
    "${cidrsubnet(local.private_cidr_block, 2, 0)}",
    "${cidrsubnet(local.private_cidr_block, 2, 1)}",
    "${cidrsubnet(local.private_cidr_block, 2, 2)}",
  ]

  public_subnets = [
    "${cidrsubnet(local.public_cidr_block, 2, 0)}",
    "${cidrsubnet(local.public_cidr_block, 2, 1)}",
    "${cidrsubnet(local.public_cidr_block, 2, 2)}",
  ]

  elasticache_subnets = [
    "${cidrsubnet(local.elasticache_cidr_block, 2, 0)}",
    "${cidrsubnet(local.elasticache_cidr_block, 2, 1)}",
    "${cidrsubnet(local.elasticache_cidr_block, 2, 2)}",
  ]

  database_subnets = [
    "${cidrsubnet(local.db_cidr_block, 2, 0)}",
    "${cidrsubnet(local.db_cidr_block, 2, 1)}",
    "${cidrsubnet(local.db_cidr_block, 2, 2)}",
  ]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_s3_endpoint = true

  tags = "${
    map(
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"

  private_subnet_tags = "${
    map(
      "kubernetes.io/role/internal-elb", "",
    )
  }"

  public_subnet_tags = "${
    map(
      "kubernetes.io/role/elb", "",
    )
  }"
}

// Include this so default route table gets tagged with the cluster and name
resource "aws_default_route_table" "r" {
  default_route_table_id = "${module.vpc.default_route_table_id}"

  tags = "${
    map(
      "Name", "${var.env}-default",
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

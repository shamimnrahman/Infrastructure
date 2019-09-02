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

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    region       = "${var.tfstate_region}"
    bucket       = "${var.tfstate_bucket}"
    key          = "${var.env}/${var.db_state_name}/terraform.tfstate"
    profile      = "${var.aws_profile}"
    dynodb_table = "${var.tfstate_lock_table}"
  }
}

data "terraform_remote_state" "redis" {
  backend = "s3"

  config {
    region       = "${var.tfstate_region}"
    bucket       = "${var.tfstate_bucket}"
    key          = "${var.env}/${var.redis_state_name}/terraform.tfstate"
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
  db_host   = "${data.terraform_remote_state.db.host}"
  db_name   = "${data.terraform_remote_state.db.name}"
  db_pass   = "${data.terraform_remote_state.db.password}"
  db_user   = "${data.terraform_remote_state.db.username}"
  db_port   = "${data.terraform_remote_state.db.port}"
  db_url    = "postgresql://${local.db_user}:${urlencode(local.db_pass)}@${local.db_host}/${local.db_name}?sslmode=require"
  rails_env = "${var.env == "prod" ? "production" : "development"}"
}

resource "kubernetes_config_map" "this" {
  metadata {
    name      = "${var.configmap_name}"
    namespace = "${var.configmap_namespace_prefix}-${var.env}"
  }

  data {
    databaseHost              = "${local.db_host}"
    databaseName              = "${local.db_name}"
    databaseUser              = "${local.db_user}"
    databasePassword          = "${local.db_pass}"
    databasePort              = "${local.db_port}"
    databaseUrl               = "${local.db_url}"
    dbCleanerAllowRemoteDbUrl = "true"
    environment               = "${local.rails_env}"
    redisUrl                  = "rediss://${data.terraform_remote_state.redis.host}:${data.terraform_remote_state.redis.port}/0"
  }
}

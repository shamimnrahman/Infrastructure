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

data "aws_route53_zone" "base" {
  name = "${var.root_domain}"
}

resource "aws_route53_zone" "k8s" {
  name    = "${var.env}.k8s.${data.aws_route53_zone.base.name}"
  comment = "Managed by Terraform for the ${var.env} environment"

  tags = "${
    map(
      "Environment", "${var.env}",
      "kubernetes.io/cluster/${var.env}", "shared",
    )
  }"
}

resource "aws_route53_record" "zone_ns" {
  zone_id = "${data.aws_route53_zone.base.zone_id}"
  name    = "${aws_route53_zone.k8s.name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.k8s.name_servers.0}",
    "${aws_route53_zone.k8s.name_servers.1}",
    "${aws_route53_zone.k8s.name_servers.2}",
    "${aws_route53_zone.k8s.name_servers.3}",
  ]
}

resource "aws_iam_policy" "zone_edit" {
  name        = "${var.env}-zone-edit-policy"
  description = "Provide permissions to allow external-dns to work for the ${var.env} cluster."

  policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/${aws_route53_zone.k8s.zone_id}"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
 ]
}
POLICY
}

// Provide the k8s workers permissions to edit the hosted zone
resource "aws_iam_role_policy_attachment" "eks_worker_zone_edit" {
  policy_arn = "${aws_iam_policy.zone_edit.arn}"
  role       = "${data.terraform_remote_state.eks.eks_worker_iam_role_name}"
}

data "template_file" "deployment" {
  template = "${file("${path.module}/k8s-manifests/deployment.yaml.tpl")}"

  vars {
    env    = "${var.env}"
    domain = "${aws_route53_zone.k8s.name}"
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

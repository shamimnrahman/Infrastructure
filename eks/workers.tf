resource "aws_iam_role" "eks_worker" {
  name = "${var.env}-eks-worker-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

// Provides permissions needed for worker nodes to find and attach to the
// cluster (see aws-auth.tf for the other thing needed to allow them to
// connect).
resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks_worker.name}"
}

// Provides permissions needed for workers to use the VPC networking (each pod
// gets an IP in the VPCs subnets).
resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks_worker.name}"
}

// Provides permissions for workers to access ECR to pull container images.
resource "aws_iam_role_policy_attachment" "eks_worker_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks_worker.name}"
}

resource "aws_iam_instance_profile" "eks_worker" {
  name = "${var.env}-eks-worker"
  role = "${aws_iam_role.eks_worker.name}"
}

resource "aws_security_group" "eks_worker" {
  name        = "${var.env}-eks-worker"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "${var.env} EKS Worker Security Group",
     "Environment", "${var.env}",
     "kubernetes.io/cluster/${var.env}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks_worker_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks_worker.id}"
  source_security_group_id = "${aws_security_group.eks_worker.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_worker_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks_worker.id}"
  source_security_group_id = "${aws_security_group.eks_cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks_worker" {
  filter {
    name   = "name"
    values = ["eks-worker-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml
locals {
  worker_node_userdata = <<USERDATA
#!/bin/bash -xe
CA_CERTIFICATE_DIRECTORY=/etc/kubernetes/pki
CA_CERTIFICATE_FILE_PATH=$CA_CERTIFICATE_DIRECTORY/ca.crt
mkdir -p $CA_CERTIFICATE_DIRECTORY
echo "${aws_eks_cluster.cluster.certificate_authority.0.data}" | base64 -d >  $CA_CERTIFICATE_FILE_PATH
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.cluster.endpoint},g /var/lib/kubelet/kubeconfig
sed -i s,CLUSTER_NAME,${var.env},g /var/lib/kubelet/kubeconfig
sed -i s,REGION,${var.aws_region},g /etc/systemd/system/kubelet.service
sed -i s,MAX_PODS,20,g /etc/systemd/system/kubelet.service
sed -i s,MASTER_ENDPOINT,${aws_eks_cluster.cluster.endpoint},g /etc/systemd/system/kubelet.service
sed -i s,INTERNAL_IP,$INTERNAL_IP,g /etc/systemd/system/kubelet.service
DNS_CLUSTER_IP=10.100.0.10
if [[ $INTERNAL_IP == 10.* ]] ; then DNS_CLUSTER_IP=172.20.0.10; fi
sed -i s,DNS_CLUSTER_IP,$DNS_CLUSTER_IP,g /etc/systemd/system/kubelet.service
sed -i s,CERTIFICATE_AUTHORITY_FILE,$CA_CERTIFICATE_FILE_PATH,g /var/lib/kubelet/kubeconfig
sed -i s,CLIENT_CA_FILE,$CA_CERTIFICATE_FILE_PATH,g  /etc/systemd/system/kubelet.service
systemctl daemon-reload
systemctl restart kubelet
USERDATA
}

resource "aws_launch_configuration" "private_worker" {
  associate_public_ip_address = false
  iam_instance_profile        = "${aws_iam_instance_profile.eks_worker.name}"
  image_id                    = "${data.aws_ami.eks_worker.id}"
  instance_type               = "${var.worker_type}"
  name_prefix                 = "${var.env}-eks-private-worker"
  security_groups             = ["${aws_security_group.eks_worker.id}"]
  user_data_base64            = "${base64encode(local.worker_node_userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "private_worker" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.private_worker.name}"
  max_size             = 6
  min_size             = 1
  name                 = "${var.env}-eks-private-worker"
  termination_policies = ["OldestLaunchConfiguration", "OldestInstance", "Default"]
  vpc_zone_identifier  = ["${data.terraform_remote_state.vpc.private_subnet_ids}"]

  tag {
    key                 = "Name"
    value               = "${var.env} EKS Private Worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.env}"
    value               = "owned"
    propagate_at_launch = true
  }
}

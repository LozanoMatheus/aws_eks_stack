data "aws_availability_zones" "available" {}

resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"

  tags = map(
      "Name", "${var.cluster_name}-node",
      "kubernetes.io/cluster/${var.cluster_name}", "shared",
      "k8s.io/cluster-autoscaler/${var.cluster_name}", "true",
      "k8s.io/cluster-autoscaler/enabled", "true",
    )
}

resource "aws_subnet" "eks" {
  count = 2

  map_public_ip_on_launch = true

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.eks.id

  tags = map(
      "Name", "${var.cluster_name}-node",
      "kubernetes.io/cluster/${var.cluster_name}", "shared",
      "k8s.io/cluster-autoscaler/${var.cluster_name}", "true",
      "k8s.io/cluster-autoscaler/enabled", "true",
    )
}

resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = map(
      "Name", var.cluster_name,
      "kubernetes.io/cluster/${var.cluster_name}", "shared",
      "k8s.io/cluster-autoscaler/${var.cluster_name}", "true",
      "k8s.io/cluster-autoscaler/enabled", "true",
    )
}

resource "aws_route_table" "eks" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }
}

resource "aws_route_table_association" "eks" {
  count = 2

  subnet_id      = aws_subnet.eks.*.id[count.index]
  route_table_id = aws_route_table.eks.id
}

resource "aws_iam_role" "eks-cluster" {
  name = "${var.cluster_name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = aws_iam_role.eks-cluster.name
}

resource "aws_security_group" "eks-cluster" {
  name = "${var.cluster_name}-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id = aws_vpc.eks.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
      "Name", var.cluster_name,
      "kubernetes.io/cluster/${var.cluster_name}", "shared",
      "k8s.io/cluster-autoscaler/${var.cluster_name}", "true",
      "k8s.io/cluster-autoscaler/enabled", "true",
    )
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "eks-cluster-ingress-workstation-https" {
  cidr_blocks = ["${var.my_public_ip}/32"]
  description = "Allow workstation to communicate with the cluster API Server"
  from_port = 443
  protocol = "tcp"
  security_group_id = aws_security_group.eks-cluster.id
  to_port = 443
  type = "ingress"
}

resource "aws_eks_cluster" "eks" {
  name = var.cluster_name
  role_arn = aws_iam_role.eks-cluster.arn
  version = var.eks_version

  vpc_config {
    security_group_ids = [aws_security_group.eks-cluster.id]
    subnet_ids = aws_subnet.eks.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
    aws_subnet.eks,
  ]
}

locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.eks.endpoint}
    certificate-authority-data: ${aws_eks_cluster.eks.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster_name}"
KUBECONFIG
}

output "kubeconfig" {
  value = local.kubeconfig
}

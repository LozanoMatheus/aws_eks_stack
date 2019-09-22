variable "cluster_name" {
  description = "Cluster name"
  type        = "string"
}

variable "eks_version" {
  default = "1.13"
}

variable "my_public_ip" {
  description = "My public IP address"
}

variable "aws_region" {
  description = "AWS Region"
}

variable "instance_type" {
  description = "AWS EC2 instance type for workers"
}

variable "ssh_key_name" {
  description = "SSH Key to access worker nodes"
}

variable "ssh_key_path" {
  description = "SSH Key to access worker nodes"
}
